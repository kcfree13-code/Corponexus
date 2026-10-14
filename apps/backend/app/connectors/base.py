import httpx
from typing import Optional, Dict, Any


class BaseConnector:
    def __init__(self, user_agent: Optional[str] = None, timeout: float = 15.0):
        self.timeout = timeout
        self.headers: Dict[str, str] = {
            "Accept": "application/json",
        }
        if user_agent:
            self.headers["User-Agent"] = user_agent

    async def get(self, url: str, params: Optional[Dict[str, Any]] = None, extra_headers: Optional[Dict[str, str]] = None) -> httpx.Response:
        req_headers = {**self.headers, **(extra_headers or {})}
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(url, params=params, headers=req_headers)
            response.raise_for_status()
            return response
