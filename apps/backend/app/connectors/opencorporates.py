from typing import Optional, Dict, Any, List
import httpx
from app.connectors.base import BaseConnector
from app.core.config import settings


class OpenCorporatesConnector(BaseConnector):
    def __init__(self, api_token: Optional[str] = None):
        super().__init__(user_agent="CorpNexus CorporateIntelligence/1.0")
        self.api_token = api_token
        self.base_url = settings.OPENCORPORATES_API_BASE

    def _params(self, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        p = params.copy() if params else {}
        if self.api_token:
            p["api_token"] = self.api_token
        return p

    async def verify_token(self) -> bool:
        """Tests the user's personal OpenCorporates API key"""
        if not self.api_token:
            return False
        try:
            url = f"{self.base_url}/companies/search"
            resp = await self.get(url, params={"q": "OpenCorporates", "api_token": self.api_token})
            return resp.status_code == 200
        except Exception:
            return False

    async def search_companies(self, query: str, jurisdiction: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"{self.base_url}/companies/search"
        params: Dict[str, Any] = {"q": query}
        if jurisdiction:
            params["jurisdiction_code"] = jurisdiction
        params = self._params(params)
        
        try:
            resp = await self.get(url, params=params)
            data = resp.json()
            companies = data.get("results", {}).get("companies", [])
            return [c.get("company", {}) for c in companies]
        except httpx.HTTPError:
            return []

    async def get_company_details(self, jurisdiction_code: str, company_number: str) -> Optional[Dict[str, Any]]:
        url = f"{self.base_url}/companies/{jurisdiction_code}/{company_number}"
        params = self._params()
        try:
            resp = await self.get(url, params=params)
            data = resp.json()
            return data.get("results", {}).get("company")
        except httpx.HTTPError:
            return None
