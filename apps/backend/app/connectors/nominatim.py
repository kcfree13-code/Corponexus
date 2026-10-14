import hashlib
from typing import Optional, Tuple
import httpx
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.connectors.base import BaseConnector
from app.core.config import settings
from app.models import GeocodedAddress, SourceCitation


class NominatimConnector(BaseConnector):
    def __init__(self):
        super().__init__(user_agent=settings.NOMINATIM_USER_AGENT)
        self.base_url = "https://nominatim.openstreetmap.org/search"

    @staticmethod
    def hash_address(address: str) -> str:
        return hashlib.sha256(address.strip().lower().encode("utf-8")).hexdigest()

    async def geocode_address(self, address: str, db: AsyncSession) -> Optional[Tuple[float, float, str]]:
        """
        Geocodes address string to (latitude, longitude, source_citation_id).
        Checks DB cache first. If found, returns without calling OpenStreetMap API.
        If not found, fetches from Nominatim, stores in cache, and returns coordinates.
        """
        if not address or len(address.strip()) < 3:
            return None

        addr_hash = self.hash_address(address)

        # 1. Check permanent cache
        stmt = select(GeocodedAddress).where(GeocodedAddress.address_hash == addr_hash)
        res = await db.execute(stmt)
        cached = res.scalars().first()
        if cached:
            return (cached.latitude, cached.longitude, cached.source_citation_id)

        # 2. Query Nominatim
        params = {
            "q": address,
            "format": "json",
            "limit": 1
        }
        try:
            resp = await self.get(self.base_url, params=params)
            results = resp.json()
            if not results or not isinstance(results, list):
                return None
            
            top = results[0]
            lat = float(top["lat"])
            lon = float(top["lon"])

            # 3. Create Source Citation
            citation = SourceCitation(
                source_publisher="OpenStreetMap Nominatim",
                source_url=f"https://nominatim.openstreetmap.org/ui/search.html?q={address}",
                raw_response_snippet=f"lat={lat}, lon={lon}, display_name={top.get('display_name')}"
            )
            db.add(citation)
            await db.flush()

            # 4. Save to permanent cache
            cached_entry = GeocodedAddress(
                address_hash=addr_hash,
                raw_address=address,
                latitude=lat,
                longitude=lon,
                source_citation_id=citation.id
            )
            db.add(cached_entry)
            await db.commit()

            return (lat, lon, citation.id)
        except Exception:
            return None
