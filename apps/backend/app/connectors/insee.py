from typing import Optional, Dict, Any, List
from app.connectors.base import BaseConnector
from app.core.config import settings


class InseeSireneConnector(BaseConnector):
    """
    INSEE SIRENE API Connector for official French corporate registry data.
    """
    def __init__(self, token: Optional[str] = None):
        super().__init__(user_agent="CorpNexus CorporateIntelligence/1.0")
        self.token = token
        self.base_url = settings.INSEE_SIRENE_API_BASE

    def _headers(self) -> Dict[str, str]:
        headers = {}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers

    async def get_siren_info(self, siren: str) -> Optional[Dict[str, Any]]:
        clean_siren = siren.replace(" ", "")
        url = f"{self.base_url}/siren/{clean_siren}"
        try:
            resp = await self.get(url, extra_headers=self._headers())
            data = resp.json()
            unite_legale = data.get("uniteLegale", {})
            return {
                "siren": clean_siren,
                "name": unite_legale.get("denominationUniteLegale") or f"Entreprise {clean_siren}",
                "status": "active" if unite_legale.get("etatAdministratifUniteLegale") == "A" else "dissolved",
                "incorporation_date": unite_legale.get("dateCreationUniteLegale"),
                "source_url": f"https://annuaire-entreprises.data.gouv.fr/entreprise/{clean_siren}"
            }
        except Exception:
            return None
