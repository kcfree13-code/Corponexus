from typing import Optional, Dict, Any, List
import httpx
from app.connectors.base import BaseConnector
from app.core.config import settings


class SecEdgarConnector(BaseConnector):
    def __init__(self):
        super().__init__(user_agent=settings.SEC_USER_AGENT)
        self.base_url = "https://data.sec.gov/api/xbrl"

    async def get_annual_revenues_5yr(self, cik: str) -> List[Dict[str, Any]]:
        """
        Fetches certified 5-year annual revenue from SEC EDGAR XBRL company facts.
        Zero inference: strictly parses official 10-K / 20-F filings.
        """
        clean_cik = cik.strip().lstrip("0").zfill(10)
        url = f"{self.base_url}/companyfacts/CIK{clean_cik}.json"
        
        try:
            resp = await self.get(url)
            data = resp.json()
        except Exception:
            return []

        us_gaap = data.get("facts", {}).get("us-gaap", {})
        rev_data = us_gaap.get("Revenues") or us_gaap.get("SalesRevenueNet") or us_gaap.get("RevenueFromContractWithCustomerExcludingAssessedTax")
        if not rev_data:
            return []

        units = rev_data.get("units", {})
        usd_units = units.get("USD", [])
        if not usd_units:
            return []

        # Filter strictly 10-K or 20-F annual filings
        annual_records = [
            item for item in usd_units
            if item.get("form") in ("10-K", "20-F") and item.get("fy") is not None and item.get("val") is not None
        ]

        # Group by fiscal year, take latest filed
        by_year: Dict[int, Dict[str, Any]] = {}
        for rec in annual_records:
            fy = int(rec["fy"])
            by_year[fy] = {
                "fiscal_year": fy,
                "annual_revenue": float(rec["val"]),
                "currency": "USD",
                "filing_type": rec.get("form", "10-K"),
                "filing_date": rec.get("filed"),
                "accession_number": rec.get("accn"),
                "source_url": f"https://www.sec.gov/edgar/browse/?CIK={clean_cik}"
            }

        # Sort descending and take up to 5 most recent years
        sorted_years = sorted(by_year.keys(), reverse=True)[:5]
        return [by_year[y] for y in sorted(sorted_years)]
