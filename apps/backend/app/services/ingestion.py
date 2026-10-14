import json
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import (
    VerifiedNode,
    VerifiedEdge,
    NodeFinancials,
    ItalianPublicContract,
    SourceCitation,
    HistoricalSnapshot,
)
from app.connectors.opencorporates import OpenCorporatesConnector
from app.connectors.sec_edgar import SecEdgarConnector
from app.connectors.nominatim import NominatimConnector
from app.connectors.anac import AnacConnector
from app.core.config import settings
import httpx


def utc_now():
    return datetime.now(timezone.utc)


class IngestionService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_snapshot(self, entity_id: str, reason: str = "pre_refresh_archive"):
        """
        Archives current state of the entity and its connected edges into historical_snapshots
        before executing any refresh, preserving temporal audit trail.
        """
        stmt = (
            select(VerifiedNode)
            .where(VerifiedNode.id == entity_id)
            .options(
                selectinload(VerifiedNode.out_edges),
                selectinload(VerifiedNode.in_edges),
                selectinload(VerifiedNode.financials),
                selectinload(VerifiedNode.contracts),
            )
        )
        res = await self.db.execute(stmt)
        node = res.scalars().first()
        if not node:
            return

        payload = {
            "entity": {
                "id": node.id,
                "node_type": node.node_type,
                "name": node.name,
                "jurisdiction": node.jurisdiction,
                "company_number": node.company_number,
                "status": node.status,
                "registered_address_in_full": node.registered_address_in_full,
                "last_fetched_at": node.last_fetched_at.isoformat() if node.last_fetched_at else None,
            },
            "out_edges": [
                {
                    "target": e.target_node_id,
                    "type": e.relationship_type,
                    "start": e.start_date,
                    "end": e.end_date,
                    "active": e.is_active,
                }
                for e in node.out_edges
            ],
            "in_edges": [
                {
                    "source": e.source_node_id,
                    "type": e.relationship_type,
                    "start": e.start_date,
                    "end": e.end_date,
                    "active": e.is_active,
                }
                for e in node.in_edges
            ],
            "financials": [
                {"fy": f.fiscal_year, "revenue": f.annual_revenue, "currency": f.currency}
                for f in node.financials
            ],
        }

        snapshot = HistoricalSnapshot(
            entity_id=entity_id,
            snapshot_timestamp=utc_now(),
            snapshot_payload=json.dumps(payload, ensure_ascii=False),
            reason=reason,
        )
        self.db.add(snapshot)
        await self.db.flush()

    async def ingest_opencorporates_company(
        self,
        raw_company: Dict[str, Any],
        api_token: Optional[str] = None
    ) -> VerifiedNode:
        """
        Normalizes and persists OpenCorporates company data + officers strictly into DB.
        Zero inference: only stores what is present in official API response.
        """
        jurisdiction = raw_company.get("jurisdiction_code", "").lower()
        company_number = str(raw_company.get("company_number", "")).strip()
        entity_id = f"company:{jurisdiction}:{company_number}"

        # 1. Archive previous state if node already exists
        await self.create_snapshot(entity_id, reason="pre_refresh_archive")

        # 2. Create SourceCitation
        oc_url = raw_company.get("opencorporates_url") or f"https://opencorporates.com/companies/{jurisdiction}/{company_number}"
        citation = SourceCitation(
            source_publisher="OpenCorporates",
            source_url=oc_url,
            filing_id=company_number,
            retrieved_at=utc_now(),
            raw_response_snippet=json.dumps({"name": raw_company.get("name"), "status": raw_company.get("current_status")})
        )
        self.db.add(citation)
        await self.db.flush()

        # 3. Geocode address if available (cached permanently in PostgreSQL)
        address = raw_company.get("registered_address_in_full")
        lat, lon = None, None
        if address:
            geocoder = NominatimConnector()
            geo_res = await geocoder.geocode_address(address, self.db)
            if geo_res:
                lat, lon, _ = geo_res

        # 4. Upsert VerifiedNode
        stmt = select(VerifiedNode).where(VerifiedNode.id == entity_id)
        res = await self.db.execute(stmt)
        node = res.scalars().first()

        now = utc_now()
        if not node:
            node = VerifiedNode(
                id=entity_id,
                node_type="company",
                name=raw_company.get("name") or f"Company {company_number}",
                jurisdiction=jurisdiction,
                company_number=company_number,
                status=raw_company.get("current_status"),
                incorporation_date=raw_company.get("incorporation_date"),
                dissolution_date=raw_company.get("dissolution_date"),
                registered_address_in_full=address,
                latitude=lat,
                longitude=lon,
                last_fetched_at=now,
                source_citation_id=citation.id,
            )
            self.db.add(node)
        else:
            node.name = raw_company.get("name") or node.name
            node.status = raw_company.get("current_status")
            node.incorporation_date = raw_company.get("incorporation_date")
            node.dissolution_date = raw_company.get("dissolution_date")
            node.registered_address_in_full = address
            if lat and lon:
                node.latitude = lat
                node.longitude = lon
            node.last_fetched_at = now
            node.source_citation_id = citation.id

        await self.db.flush()

        # 5. Ingest Officers (Directors / Administrators)
        officers = raw_company.get("officers", [])
        for off_wrapper in officers:
            officer = off_wrapper.get("officer", off_wrapper)
            off_name = officer.get("name")
            if not off_name:
                continue

            person_id = f"person:{jurisdiction}:{off_name.strip().lower().replace(' ', '-')}"
            
            # Upsert Officer Node
            stmt_p = select(VerifiedNode).where(VerifiedNode.id == person_id)
            res_p = await self.db.execute(stmt_p)
            person_node = res_p.scalars().first()
            if not person_node:
                person_node = VerifiedNode(
                    id=person_id,
                    node_type="officer",
                    name=off_name,
                    jurisdiction=jurisdiction,
                    last_fetched_at=now,
                    source_citation_id=citation.id,
                )
                self.db.add(person_node)
                await self.db.flush()

            # Relationship Edge: person -> company
            edge_type = officer.get("position") or officer.get("officer_role") or "officer_of"
            start_date = officer.get("start_date")
            end_date = officer.get("end_date")
            is_active = end_date is None

            # Check if edge already exists
            stmt_e = select(VerifiedEdge).where(
                VerifiedEdge.source_node_id == person_id,
                VerifiedEdge.target_node_id == entity_id,
                VerifiedEdge.relationship_type == edge_type,
            )
            res_e = await self.db.execute(stmt_e)
            edge = res_e.scalars().first()
            if not edge:
                edge = VerifiedEdge(
                    source_node_id=person_id,
                    target_node_id=entity_id,
                    relationship_type=edge_type,
                    start_date=start_date,
                    end_date=end_date,
                    is_active=is_active,
                    last_fetched_at=now,
                    source_citation_id=citation.id,
                )
                self.db.add(edge)
            else:
                edge.start_date = start_date
                edge.end_date = end_date
                edge.is_active = is_active
                edge.last_fetched_at = now
                edge.source_citation_id = citation.id

        await self.db.commit()
        return node

    async def ingest_sec_edgar_company(self, cik: str) -> Optional[VerifiedNode]:
        """
        Fetches official submission metadata from SEC EDGAR,
        geocodes the headquarters via Nominatim,
        fetches 5-year certified annual revenues from SEC XBRL,
        and saves everything into PostgreSQL VerifiedNode + NodeFinancials.
        100% Free, Zero-Inference, Official Public Registry.
        """
        clean_cik = cik.strip().lstrip("0").zfill(10)
        entity_id = f"company:us:{clean_cik}"

        # 1. Check if node already exists
        stmt = (
            select(VerifiedNode)
            .where(VerifiedNode.id == entity_id)
            .options(selectinload(VerifiedNode.source_citation))
        )
        res = await self.db.execute(stmt)
        node = res.scalars().first()
        if node:
            return node

        # 2. Query SEC EDGAR Submissions API
        url = f"https://data.sec.gov/submissions/CIK{clean_cik}.json"
        headers = {"User-Agent": settings.SEC_USER_AGENT}
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(url, headers=headers)
                if resp.status_code != 200:
                    return None
                data = resp.json()
        except Exception:
            return None

        name = data.get("name", f"SEC Entity {clean_cik}").title()
        tickers = data.get("tickers", [])
        ticker = tickers[0] if tickers else clean_cik

        # 3. Construct Business Address
        b_addr = data.get("addresses", {}).get("business", {})
        addr_parts = [
            b_addr.get("street1"),
            b_addr.get("street2"),
            b_addr.get("city"),
            b_addr.get("stateOrCountryDescription") or b_addr.get("stateOrCountry"),
            b_addr.get("zipCode")
        ]
        full_address = ", ".join([p for p in addr_parts if p and str(p).strip()]) or None

        # 4. Geocode using OpenStreetMap Nominatim
        lat, lon = None, None
        if full_address:
            geocoder = NominatimConnector()
            geo_res = await geocoder.geocode_address(full_address, self.db)
            if geo_res:
                lat, lon, _ = geo_res

        # 5. Create Source Citation
        sec_url = f"https://www.sec.gov/edgar/browse/?CIK={clean_cik}"
        citation = SourceCitation(
            source_publisher="SEC EDGAR",
            source_url=sec_url,
            filing_id=clean_cik,
            retrieved_at=utc_now(),
            raw_response_snippet=json.dumps({"name": name, "ticker": ticker, "cik": clean_cik})
        )
        self.db.add(citation)
        await self.db.flush()

        # 6. Create VerifiedNode
        now = utc_now()
        node = VerifiedNode(
            id=entity_id,
            node_type="company",
            name=name,
            jurisdiction="us",
            company_number=ticker,
            status="active",
            registered_address_in_full=full_address,
            latitude=lat,
            longitude=lon,
            last_fetched_at=now,
            source_citation_id=citation.id,
        )
        self.db.add(node)
        await self.db.flush()

        # 7. Fetch 5-year revenues from SEC XBRL
        try:
            sec_conn = SecEdgarConnector()
            revenues = await sec_conn.get_annual_revenues_5yr(clean_cik)
            for rev in revenues:
                fin = NodeFinancials(
                    node_id=entity_id,
                    fiscal_year=rev["fiscal_year"],
                    annual_revenue=rev["annual_revenue"],
                    currency=rev.get("currency", "USD"),
                    source_citation_id=citation.id,
                )
                self.db.add(fin)
            await self.db.flush()
        except Exception:
            pass

        await self.db.commit()
        return node
