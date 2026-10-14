from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.models import (
    VerifiedNode,
    VerifiedEdge,
    NodeFinancials,
    ItalianPublicContract,
    SourceCitation,
)
from app.schemas import (
    CompanyDossierResponse,
    VerifiedNodeSchema,
    NodeFinancialsSchema,
    ItalianContractSchema,
    SourceCitationSchema,
)

router = APIRouter(prefix="/company", tags=["Company Intelligence Dossier"])


@router.get("/{company_id}/dossier", response_model=CompanyDossierResponse)
async def get_company_dossier(
    company_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Returns full official dossier:
    - Verified company metadata & coordinates
    - 5-Year certified annual revenues (SEC EDGAR / Official filings)
    - Italian public procurement contracts (ANAC / OpenCoesione)
    - Officers and Directors
    - Inspectable source citations
    - Explicit notices for missing official data (Strict Zero-Inference Policy)
    """
    stmt = (
        select(VerifiedNode)
        .where(VerifiedNode.id == company_id)
        .options(
            selectinload(VerifiedNode.source_citation),
            selectinload(VerifiedNode.financials).selectinload(NodeFinancials.source_citation),
            selectinload(VerifiedNode.contracts).selectinload(ItalianPublicContract.source_citation),
        )
    )
    res = await db.execute(stmt)
    node = res.scalars().first()

    if not node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Dossier per l'azienda '{company_id}' non presente nel database."
        )

    # 1. Fetch connected officers
    stmt_edges = (
        select(VerifiedEdge)
        .where(VerifiedEdge.target_node_id == company_id, VerifiedEdge.is_active == True)
        .options(selectinload(VerifiedEdge.source_citation))
    )
    edges = (await db.execute(stmt_edges)).scalars().all()
    officer_ids = [e.source_node_id for e in edges]

    officers = []
    if officer_ids:
        stmt_officers = (
            select(VerifiedNode)
            .where(VerifiedNode.id.in_(officer_ids))
            .options(selectinload(VerifiedNode.source_citation))
        )
        officers = (await db.execute(stmt_officers)).scalars().all()

    # 2. Collect all citations
    citation_ids = set()
    if node.source_citation_id:
        citation_ids.add(node.source_citation_id)
    for f in node.financials:
        if f.source_citation_id:
            citation_ids.add(f.source_citation_id)
    for c in node.contracts:
        if c.source_citation_id:
            citation_ids.add(c.source_citation_id)
    for o in officers:
        if o.source_citation_id:
            citation_ids.add(o.source_citation_id)

    citations = []
    if citation_ids:
        stmt_cit = select(SourceCitation).where(SourceCitation.id.in_(citation_ids))
        citations = (await db.execute(stmt_cit)).scalars().all()

    # 3. Missing Data Notices (Mandatory Zero-Inference Policy)
    missing_notices = []
    if not node.financials:
        missing_notices.append("Dato sui ricavi quinquennali non disponibile nei registri ufficiali (SEC / Bilanci depositati).")
    if not node.contracts:
        missing_notices.append("Nessun appalto pubblico ANAC registrato per questo codice fiscale.")
    if not node.registered_address_in_full:
        missing_notices.append("Indirizzo della sede legale non specificato nel registro ufficiale.")
    if node.latitude is None or node.longitude is None:
        missing_notices.append("Coordinate geografiche non geocodificabili per l'indirizzo dichiarato.")

    return CompanyDossierResponse(
        node=VerifiedNodeSchema.model_validate(node),
        financials=[NodeFinancialsSchema.model_validate(f) for f in node.financials],
        contracts=[ItalianContractSchema.model_validate(c) for c in node.contracts],
        officers=[VerifiedNodeSchema.model_validate(o) for o in officers],
        citations=[SourceCitationSchema.model_validate(cit) for cit in citations],
        last_fetched_at=node.last_fetched_at,
        missing_data_notices=missing_notices
    )
