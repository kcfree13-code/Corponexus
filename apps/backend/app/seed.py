import asyncio
from app.core.database import AsyncSessionLocal, init_db
from app.models import (
    SourceCitation,
    VerifiedNode,
    VerifiedEdge,
    NodeFinancials,
    ItalianPublicContract
)


async def seed():
    print("Inizializzazione database...")
    await init_db()

    async with AsyncSessionLocal() as db:
        # Check if already seeded
        from sqlalchemy.future import select
        res = await db.execute(select(VerifiedNode).where(VerifiedNode.id == "company:it:01234567890"))
        if res.scalars().first():
            print("Database già popolato con dati di test.")
            return

        print("Inserimento citazione fonti ufficiali...")
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

        print("Inserimento nodi verificati...")
        # Azienda 1: Nexus Tech S.p.A.
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
        # Amministratore: Mario Rossi
        officer_x = VerifiedNode(
            id="person:it:mario-rossi",
            node_type="officer",
            name="Mario Rossi",
            jurisdiction="it",
            source_citation_id=cit_oc.id
        )
        # Azienda 2: Global Holdings Italia S.r.l.
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
        # Titolare Effettivo: Elena Bianchi
        ubo_y = VerifiedNode(
            id="person:it:elena-bianchi",
            node_type="beneficial_owner",
            name="Elena Bianchi",
            jurisdiction="it",
            source_citation_id=cit_oc.id
        )
        db.add_all([comp_a, officer_x, comp_b, ubo_y])
        await db.flush()

        print("Inserimento relazioni (edges)...")
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

        print("Inserimento ricavi certificati 5 anni...")
        financials = [
            (2021, 12500000.0),
            (2022, 14800000.0),
            (2023, 18200000.0),
            (2024, 21900000.0),
            (2025, 26400000.0),
        ]
        for fy, rev in financials:
            db.add(NodeFinancials(
                node_id=comp_a.id,
                fiscal_year=fy,
                annual_revenue=rev,
                currency="EUR",
                filing_type="Bilancio Ordinario Depositato",
                filing_date=f"{fy+1}-04-30",
                source_citation_id=cit_sec.id
            ))

        print("Inserimento appalti pubblici ANAC...")
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
        print("Seed completato con successo! Entità pronte per test locali.")


if __name__ == "__main__":
    asyncio.run(seed())
