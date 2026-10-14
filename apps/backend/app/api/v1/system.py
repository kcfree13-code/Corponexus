from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.database import get_db, init_db
from app.models import (
    SourceCitation,
    VerifiedNode,
    VerifiedEdge,
    NodeFinancials,
    ItalianPublicContract
)

router = APIRouter(prefix="/system", tags=["System & Admin Utilities"])


@router.post("/seed", summary="Inizializza il database con entità certificate di test")
async def seed_database(db: AsyncSession = Depends(get_db)):
    """
    Popola il database PostgreSQL (locale o su Railway) con entità aziendali ed esponenti certificati
    per consentire test immediati senza consumare quote API esterne.
    """
    await init_db()
    res = await db.execute(select(VerifiedNode).where(VerifiedNode.id == "company:it:01234567890"))
    if res.scalars().first():
        return {
            "status": "already_seeded",
            "message": "Il database contiene già i dati di test (Nexus Tech S.p.A. e soggetti collegati)."
        }

    # 1. Citazioni Ufficiali
    cit_oc = SourceCitation(
        id="cit-seed-oc",
        source_publisher="OpenCorporates",
        source_url="https://opencorporates.com/companies/it/01234567890",
        filing_id="REG-MI-2024-9981",
        raw_response_snippet="Visura camerale Registro Imprese Milano"
    )
    cit_sec = SourceCitation(
        id="cit-seed-sec",
        source_publisher="SEC EDGAR",
        source_url="https://www.sec.gov/edgar/browse/?CIK=0001800000",
        filing_id="0001800000-24-000010",
        raw_response_snippet="Form 10-K Annual Report Filed 2024"
    )
    cit_anac = SourceCitation(
        id="cit-seed-anac",
        source_publisher="ANAC",
        source_url="https://dati.anticorruzione.it/opendata/tender/98765432AB",
        filing_id="CIG-98765432AB",
        raw_response_snippet="Aggiudicazione definitiva bando pubblico"
    )
    db.add_all([cit_oc, cit_sec, cit_anac])
    await db.flush()

    # 2. Nodi Verificati
    comp_a = VerifiedNode(
        id="company:it:01234567890",
        node_type="company",
        name="Nexus Tech S.p.A.",
        jurisdiction="it",
        company_number="01234567890",
        status="active",
        incorporation_date="2015-05-12",
        registered_address_in_full="Via Montenapoleone 8, 20121 Milano, Italia",
        latitude=45.4697,
        longitude=9.1952,
        source_citation_id=cit_oc.id
    )
    officer_x = VerifiedNode(
        id="person:it:mario-rossi",
        node_type="officer",
        name="Mario Rossi",
        jurisdiction="it",
        source_citation_id=cit_oc.id
    )
    comp_b = VerifiedNode(
        id="company:it:98765432100",
        node_type="company",
        name="Global Holdings Italia S.r.l.",
        jurisdiction="it",
        company_number="98765432100",
        status="active",
        incorporation_date="2010-02-01",
        registered_address_in_full="Corso Vittorio Emanuele II 10, 00186 Roma, Italia",
        latitude=41.8978,
        longitude=12.4764,
        source_citation_id=cit_oc.id
    )
    ubo_y = VerifiedNode(
        id="person:it:elena-bianchi",
        node_type="beneficial_owner",
        name="Elena Bianchi",
        jurisdiction="it",
        source_citation_id=cit_oc.id
    )
    db.add_all([comp_a, officer_x, comp_b, ubo_y])
    await db.flush()

    # 3. Relazioni
    edge_1 = VerifiedEdge(
        source_node_id=officer_x.id,
        target_node_id=comp_a.id,
        relationship_type="Amministratore Delegato",
        start_date="2016-01-01",
        is_active=True,
        source_citation_id=cit_oc.id
    )
    edge_2 = VerifiedEdge(
        source_node_id=officer_x.id,
        target_node_id=comp_b.id,
        relationship_type="Consigliere di Amministrazione",
        start_date="2018-06-01",
        is_active=True,
        source_citation_id=cit_oc.id
    )
    edge_3 = VerifiedEdge(
        source_node_id=ubo_y.id,
        target_node_id=comp_b.id,
        relationship_type="Titolare Effettivo (UBO 75%)",
        start_date="2012-03-10",
        is_active=True,
        ownership_percentage=75.0,
        source_citation_id=cit_oc.id
    )
    db.add_all([edge_1, edge_2, edge_3])

    # 4. Ricavi Certificati 5 Anni
    for fy, rev in [(2021, 12500000.0), (2022, 14800000.0), (2023, 18200000.0), (2024, 21900000.0), (2025, 26400000.0)]:
        db.add(NodeFinancials(
            node_id=comp_a.id,
            fiscal_year=fy,
            annual_revenue=rev,
            currency="EUR",
            filing_type="Bilancio Ordinario Depositato",
            filing_date=f"{fy+1}-04-30",
            source_citation_id=cit_sec.id
        ))

    # 5. Appalto ANAC
    contract = ItalianPublicContract(
        company_node_id=comp_a.id,
        cig="98765432AB",
        contract_title="Fornitura Servizi Cloud e Data Intelligence Forense",
        awarded_amount=480000.0,
        currency="EUR",
        award_date="2024-03-15",
        contracting_authority="Ministero dell'Interno",
        source_citation_id=cit_anac.id
    )
    db.add(contract)

    await db.commit()

    return {
        "status": "success",
        "message": "Database inizializzato con successo: 4 nodi, 3 relazioni, 5 bilanci e 1 appalto ANAC.",
        "sample_entities": [
            "company:it:01234567890 (Nexus Tech S.p.A.)",
            "company:it:98765432100 (Global Holdings Italia S.r.l.)",
            "person:it:mario-rossi (Amministratore comune)"
        ]
    }
