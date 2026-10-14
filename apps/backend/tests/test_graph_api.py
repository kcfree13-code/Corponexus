import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_entity_graph_cached(client: AsyncClient, seed_data):
    # Company A exists in cache -> must return 200 with 0 external API calls
    response = await client.get("/api/v1/graph/entity/company:it:01234567890?degrees=1")
    assert response.status_code == 200
    data = response.json()
    assert data["center_node_id"] == "company:it:01234567890"
    assert data["total_nodes"] >= 2  # Nexus Tech and Mario Rossi
    assert data["total_edges"] >= 1
    assert data["is_truncated"] is False
    assert data["last_fetched_at"] is not None


@pytest.mark.asyncio
async def test_shortest_path_finder(client: AsyncClient, seed_data):
    # Company A <-> Mario Rossi <-> Company B
    source = "company:it:01234567890"
    target = "company:it:98765432100"
    response = await client.get(f"/api/v1/graph/shortest-path?source={source}&target={target}&max_degrees=3")
    assert response.status_code == 200
    data = response.json()
    assert data["found"] is True
    assert data["length"] == 2  # 2 hops (Company A -> Officer -> Company B)
    node_ids = [n["id"] for n in data["path_nodes"]]
    assert node_ids == [source, "person:it:mario-rossi", target]


@pytest.mark.asyncio
async def test_company_dossier_with_5yr_revenue_and_citations(client: AsyncClient, seed_data):
    response = await client.get("/api/v1/company/company:it:01234567890/dossier")
    assert response.status_code == 200
    data = response.json()
    assert data["node"]["name"] == "Nexus Tech S.p.A."
    
    # 5-Year Certified Financials
    financials = data["financials"]
    assert len(financials) == 5
    years = [f["fiscal_year"] for f in financials]
    assert 2025 in years and 2021 in years

    # ANAC Public Contract
    contracts = data["contracts"]
    assert len(contracts) == 1
    assert contracts[0]["cig"] == "98765432AB"
    assert contracts[0]["awarded_amount"] == 450000.0

    # Officers
    assert len(data["officers"]) >= 1

    # Official Source Citations
    assert len(data["citations"]) >= 1
    assert data["citations"][0]["source_publisher"] == "OpenCorporates"


@pytest.mark.asyncio
async def test_historical_graph(client: AsyncClient, seed_data):
    response = await client.get("/api/v1/graph/historical?entity_id=company:it:01234567890&date=2020-01-01")
    assert response.status_code == 200
    data = response.json()
    assert data["center_node_id"] == "company:it:01234567890"
    assert "2020-01-01" in data["warning"]


@pytest.mark.asyncio
async def test_search_entities(client: AsyncClient, seed_data):
    response = await client.get("/api/v1/search?q=Nexus")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert data["results"][0]["name"] == "Nexus Tech S.p.A."


@pytest.mark.asyncio
async def test_search_sec_index(client: AsyncClient, seed_data):
    response = await client.get("/api/v1/search?q=Apple")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    names = [r["name"] for r in data["results"]]
    assert any("Apple" in n for n in names)
