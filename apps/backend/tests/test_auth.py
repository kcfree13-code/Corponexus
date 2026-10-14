import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_legal_consent_success(client: AsyncClient):
    payload = {
        "clause_1_byok_accepted": True,
        "clause_2_shared_cache_accepted": True,
        "clause_3_zero_inference_disclaimer_accepted": True,
        "terms_version": "v1.0-2026-10",
        "app_platform": "Android Flutter"
    }
    response = await client.post("/api/v1/auth/consent", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "accepted"
    assert data["terms_version"] == "v1.0-2026-10"
    assert "client_ip_hash" in data
    assert len(data["client_ip_hash"]) == 64  # SHA-256


@pytest.mark.asyncio
async def test_legal_consent_failure_when_clause_not_accepted(client: AsyncClient):
    payload = {
        "clause_1_byok_accepted": True,
        "clause_2_shared_cache_accepted": False,  # Not accepted!
        "clause_3_zero_inference_disclaimer_accepted": True,
        "terms_version": "v1.0-2026-10"
    }
    response = await client.post("/api/v1/auth/consent", json=payload)
    assert response.status_code == 400
    assert "tre clausole legali" in response.json()["detail"]


@pytest.mark.asyncio
async def test_verify_key_endpoint(client: AsyncClient):
    payload = {
        "provider": "opencorporates",
        "api_key": "invalid_test_key"
    }
    response = await client.post("/api/v1/auth/verify-key", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["provider"] == "opencorporates"
    assert "is_valid" in data
