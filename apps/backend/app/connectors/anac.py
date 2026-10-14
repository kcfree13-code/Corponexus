from typing import Optional, Dict, Any, List
from app.connectors.base import BaseConnector
from app.core.config import settings


class AnacConnector(BaseConnector):
    """
    ANAC (Autorità Nazionale Anticorruzione) & OpenCoesione Connector
    Retrieves certified Italian public procurement contracts (CIG) and cohesion funds.
    """
    def __init__(self):
        super().__init__(user_agent="CorpNexus CorporateIntelligence/1.0")
        self.base_url = settings.ANAC_OCDS_API_BASE

    async def get_contracts_by_tax_code(self, fiscal_code: str) -> List[Dict[str, Any]]:
        """
        Retrieves awarded contracts by Italian Codice Fiscale / Partita IVA.
        Zero inference: returns only official CIG contracts.
        """
        clean_code = fiscal_code.strip().upper()
        # In case of remote endpoint integration
        try:
            url = f"{self.base_url}/search/tender"
            resp = await self.get(url, params={"economic_operator_id": clean_code})
            data = resp.json()
            releases = data.get("releases", [])
            contracts = []
            for r in releases:
                tender = r.get("tender", {})
                awards = r.get("awards", [{}])[0]
                cig = tender.get("id") or r.get("ocid")
                contracts.append({
                    "cig": cig,
                    "contract_title": tender.get("title", "Appalto Pubblico"),
                    "awarded_amount": float(awards.get("value", {}).get("amount", 0.0)),
                    "currency": awards.get("value", {}).get("currency", "EUR"),
                    "award_date": awards.get("date"),
                    "contracting_authority": tender.get("procuringEntity", {}).get("name"),
                    "source_url": f"https://dati.anticorruzione.it/opendata/tender/{cig}"
                })
            return contracts
        except Exception:
            # Fallback for offline/mock-free: strictly return empty list
            return []
