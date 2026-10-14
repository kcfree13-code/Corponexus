from typing import Optional, List
from fastapi import APIRouter, Depends, Query, Header
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import or_

from app.core.database import get_db
from app.models import VerifiedNode
from app.schemas import SearchResponse, SearchItem
from app.connectors.opencorporates import OpenCorporatesConnector

router = APIRouter(prefix="/search", tags=["Search Entities"])


import time
import httpx
from typing import Optional, List, Dict, Any

_sec_cache: Optional[Dict[str, Any]] = None
_sec_cache_time: float = 0.0

async def _get_sec_tickers() -> Dict[str, Any]:
    global _sec_cache, _sec_cache_time
    now = time.time()
    if _sec_cache is None or (now - _sec_cache_time) > 86400:
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                resp = await client.get(
                    "https://www.sec.gov/files/company_tickers.json",
                    headers={"User-Agent": "CorpNexus CorporateIntelligence/1.0 (compliance@corponexus.org)"}
                )
                if resp.status_code == 200:
                    _sec_cache = resp.json()
                    _sec_cache_time = now
        except Exception:
            pass
    return _sec_cache or {}


@router.get("", response_model=SearchResponse)
async def search_entities(
    q: str = Query(..., min_length=2, description="Search keyword or company number"),
    jurisdiction: Optional[str] = Query(None, description="Jurisdiction code (e.g. it, gb, us_de)"),
    x_api_key: Optional[str] = Header(None, description="Optional OpenCorporates API Key for live external search"),
    db: AsyncSession = Depends(get_db)
):
    """
    Searches local PostgreSQL cache first.
    If no results found, queries SEC EDGAR official public company index (10,000+ companies)
    and OpenCorporates registry.
    """
    clean_q = f"%{q.strip()}%"
    conditions = [
        VerifiedNode.name.ilike(clean_q),
        VerifiedNode.company_number.ilike(clean_q),
    ]

    stmt = select(VerifiedNode).where(or_(*conditions))
    if jurisdiction:
        stmt = stmt.where(VerifiedNode.jurisdiction == jurisdiction.lower())

    res = await db.execute(stmt)
    db_nodes = res.scalars().all()

    items = [
        SearchItem(
            id=node.id,
            node_type=node.node_type,
            name=node.name,
            jurisdiction=node.jurisdiction,
            company_number=node.company_number,
            status=node.status,
            source_publisher="PostgreSQL Cache"
        )
        for node in db_nodes
    ]

    # If no local results, search SEC EDGAR official live index (Ferrari, Eni, Apple, Stellantis, etc.)
    if not items:
        tickers = await _get_sec_tickers()
        q_clean = q.strip().lower()
        matched = []
        for v in tickers.values():
            title = v.get("title", "")
            ticker = v.get("ticker", "")
            if q_clean in title.lower() or q_clean == ticker.lower():
                matched.append(v)
                if len(matched) >= 15:
                    break

        for c in matched:
            cik = str(c.get("cik_str", "")).zfill(10)
            items.append(
                SearchItem(
                    id=f"company:us:{cik}",
                    node_type="company",
                    name=c.get("title", "").title(),
                    jurisdiction="us",
                    company_number=c.get("ticker", cik),
                    status="active",
                    source_publisher="SEC EDGAR (Indice Ufficiale Depositato)"
                )
            )

    # If OpenCorporates token is provided, also query OpenCorporates
    if not items and x_api_key and not x_api_key.startswith("cx_"):
        connector = OpenCorporatesConnector(api_token=x_api_key)
        ext_comps = await connector.search_companies(query=q, jurisdiction=jurisdiction)
        for c in ext_comps:
            juris = c.get("jurisdiction_code", "")
            comp_num = str(c.get("company_number", ""))
            items.append(
                SearchItem(
                    id=f"company:{juris}:{comp_num}",
                    node_type="company",
                    name=c.get("name", ""),
                    jurisdiction=juris,
                    company_number=comp_num,
                    status=c.get("current_status"),
                    source_publisher="OpenCorporates (Live Result)"
                )
            )

    return SearchResponse(
        query=q,
        total=len(items),
        results=items
    )
