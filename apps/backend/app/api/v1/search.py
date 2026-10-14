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


@router.get("", response_model=SearchResponse)
async def search_entities(
    q: str = Query(..., min_length=2, description="Search keyword or company number"),
    jurisdiction: Optional[str] = Query(None, description="Jurisdiction code (e.g. it, gb, us_de)"),
    x_api_key: Optional[str] = Header(None, description="Optional OpenCorporates API Key for live external search"),
    db: AsyncSession = Depends(get_db)
):
    """
    Searches local PostgreSQL cache first.
    If no results found and X-API-Key is provided, searches OpenCorporates official registry.
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

    # If no results and API key is supplied, query OpenCorporates
    if not items and x_api_key:
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
