from typing import Optional, Dict, Any, List
from app.connectors.base import BaseConnector
from app.core.config import settings


class OpenOwnershipConnector(BaseConnector):
    """
    Open Ownership Register (BODS - Beneficial Ownership Data Standard) Connector.
    """
    def __init__(self, api_key: Optional[str] = None):
        super().__init__(user_agent="CorpNexus CorporateIntelligence/1.0")
        self.api_key = api_key
        self.base_url = settings.OPENOWNERSHIP_API_BASE

    async def get_beneficial_owners(self, company_number: str, jurisdiction: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"{self.base_url}/statements"
        params = {"subject": company_number}
        try:
            resp = await self.get(url, params=params)
            data = resp.json()
            statements = data.get("results", [])
            owners = []
            for stmt in statements:
                if stmt.get("statementType") == "ownershipOrControlStatement":
                    interested_party = stmt.get("interestedParty", {})
                    name = interested_party.get("name") or interested_party.get("describedByEntityStatement", {}).get("name")
                    if name:
                        owners.append({
                            "name": name,
                            "statement_id": stmt.get("statementId"),
                            "source_url": f"https://register.openownership.org/entities/{company_number}",
                            "interests": stmt.get("interests", [])
                        })
            return owners
        except Exception:
            return []
