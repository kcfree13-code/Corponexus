from typing import Optional, Dict, Any, List
from app.connectors.base import BaseConnector
from app.core.config import settings


class WikidataConnector(BaseConnector):
    """
    Wikidata SPARQL Connector for verified corporate hierarchies.
    Strictly filters statements that have official external reference URLs.
    """
    def __init__(self):
        super().__init__(user_agent="CorpNexus CorporateIntelligence/1.0 (contact: info@corponexus.org)")
        self.endpoint = settings.WIKIDATA_SPARQL_ENDPOINT

    async def get_parent_and_subsidiaries(self, wikidata_id: str) -> List[Dict[str, Any]]:
        clean_id = wikidata_id.strip().upper()
        # SPARQL query: Parent (P749) and Subsidiary (P355) with mandatory source reference
        sparql_query = f"""
        SELECT ?entity ?entityLabel ?relType ?refUrl WHERE {{
          VALUES ?company {{ wd:{clean_id} }}
          {{
            ?company p:P749 ?statement .
            ?statement ps:P749 ?entity .
            BIND("parent_company_of" AS ?relType) .
            ?statement prov:wasDerivedFrom ?ref .
            ?ref ?pr ?refUrl .
            FILTER(isURI(?refUrl))
          }} UNION {{
            ?company p:P355 ?statement .
            ?statement ps:P355 ?entity .
            BIND("subsidiary_of" AS ?relType) .
            ?statement prov:wasDerivedFrom ?ref .
            ?ref ?pr ?refUrl .
            FILTER(isURI(?refUrl))
          }}
          SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en,it,fr,de". }}
        }} LIMIT 50
        """
        try:
            resp = await self.get(self.endpoint, params={"query": sparql_query, "format": "json"})
            data = resp.json()
            bindings = data.get("results", {}).get("bindings", [])
            results = []
            for b in bindings:
                results.append({
                    "related_entity_id": b.get("entity", {}).get("value", "").split("/")[-1],
                    "related_entity_name": b.get("entityLabel", {}).get("value"),
                    "relationship_type": b.get("relType", {}).get("value"),
                    "official_reference_url": b.get("refUrl", {}).get("value")
                })
            return results
        except Exception:
            return []
