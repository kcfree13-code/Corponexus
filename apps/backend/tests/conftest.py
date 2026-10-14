import pytest
import asyncio
from typing import AsyncGenerator
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from app.core.database import Base, get_db
from app.main import app
from app.models import (
    SourceCitation,
    VerifiedNode,
    VerifiedEdge,
    NodeFinancials,
    ItalianPublicContract
)

# Use SQLite in-memory for lightning fast local unit testing without needing external services
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestingSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(autouse=True)
async def setup_test_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def seed_data():
    """Seeds verified corporate network for testing graph traversal and dossier"""
    async with TestingSessionLocal() as db:
        # 1. Source Citation
        cit = SourceCitation(
            id="cit-100",
            source_publisher="OpenCorporates",
            source_url="https://opencorporates.com/companies/it/01234567890",
            filing_id="FIL-2026-IT",
            raw_response_snippet="Official Italian Registry Extract"
        )
        db.add(cit)
        await db.flush()

        # 2. Company A (Nexus Corp)
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
            source_citation_id=cit.id
        )
        db.add(comp_a)

        # 3. Officer X (Director)
        officer_x = VerifiedNode(
            id="person:it:mario-rossi",
            node_type="officer",
            name="Mario Rossi",
            jurisdiction="it",
            source_citation_id=cit.id
        )
        db.add(officer_x)

        # 4. Company B (Global Holding)
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
            source_citation_id=cit.id
        )
        db.add(comp_b)

        # 5. Edges: Mario Rossi -> Nexus Tech (CEO) & Mario Rossi -> Global Holdings (Director)
        edge_1 = VerifiedEdge(
            id="edge-1",
            source_node_id=officer_x.id,
            target_node_id=comp_a.id,
            relationship_type="Amministratore Delegato",
            start_date="2016-01-01",
            is_active=True,
            source_citation_id=cit.id
        )
        edge_2 = VerifiedEdge(
            id="edge-2",
            source_node_id=officer_x.id,
            target_node_id=comp_b.id,
            relationship_type="Consigliere di Amministrazione",
            start_date="2018-06-01",
            is_active=True,
            source_citation_id=cit.id
        )
        db.add_all([edge_1, edge_2])

        # 6. Certified 5-Year Financials
        for year, rev in [(2021, 12000000.0), (2022, 14500000.0), (2023, 17800000.0), (2024, 21000000.0), (2025, 25400000.0)]:
            fin = NodeFinancials(
                node_id=comp_a.id,
                fiscal_year=year,
                annual_revenue=rev,
                currency="EUR",
                filing_type="Bilancio Ordinario",
                filing_date=f"{year+1}-04-30",
                source_citation_id=cit.id
            )
            db.add(fin)

        # 7. ANAC Public Contract
        contract = ItalianPublicContract(
            company_node_id=comp_a.id,
            cig="98765432AB",
            contract_title="Fornitura Servizi Cloud e Data Intelligence",
            awarded_amount=450000.0,
            currency="EUR",
            award_date="2024-03-15",
            contracting_authority="Ministero dell'Interno",
            source_citation_id=cit.id
        )
        db.add(contract)

        await db.commit()
