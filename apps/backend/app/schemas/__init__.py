from datetime import datetime
from typing import List, Optional, Any
from pydantic import BaseModel, Field, ConfigDict


# --- Auth & Consent Schemas ---

class ConsentRequest(BaseModel):
    user_id: Optional[str] = None
    terms_version: str = "v1.0-2026-10"
    clause_1_byok_accepted: bool = Field(..., description="BYOK ownership and provider terms acceptance")
    clause_2_shared_cache_accepted: bool = Field(..., description="Collaborative public cache storage acceptance")
    clause_3_zero_inference_disclaimer_accepted: bool = Field(..., description="Zero inference and manual update disclaimer")
    app_platform: str = "Android Flutter"


class ConsentResponse(BaseModel):
    id: str
    user_id: str
    status: str = "accepted"
    accepted_at: datetime
    terms_version: str
    client_ip_hash: str


class VerifyKeyRequest(BaseModel):
    provider: str = "opencorporates"  # "opencorporates", "insee"
    api_key: str


class VerifyKeyResponse(BaseModel):
    provider: str
    is_valid: bool
    message: str


# --- Provenance & Citation Schemas ---

class SourceCitationSchema(BaseModel):
    id: str
    source_publisher: str
    source_url: str
    filing_id: Optional[str] = None
    retrieved_at: datetime
    raw_response_snippet: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# --- Graph Schemas ---

class VerifiedNodeSchema(BaseModel):
    id: str
    node_type: str  # "company", "officer", "beneficial_owner"
    name: str
    jurisdiction: Optional[str] = None
    company_number: Optional[str] = None
    status: Optional[str] = None
    incorporation_date: Optional[str] = None
    dissolution_date: Optional[str] = None
    registered_address_in_full: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    last_fetched_at: datetime
    source_citation: Optional[SourceCitationSchema] = None

    model_config = ConfigDict(from_attributes=True)


class VerifiedEdgeSchema(BaseModel):
    id: str
    source_node_id: str
    target_node_id: str
    relationship_type: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: bool = True
    ownership_percentage: Optional[float] = None
    last_fetched_at: datetime
    source_citation: Optional[SourceCitationSchema] = None

    model_config = ConfigDict(from_attributes=True)


class GraphResponse(BaseModel):
    center_node_id: Optional[str] = None
    nodes: List[VerifiedNodeSchema] = []
    edges: List[VerifiedEdgeSchema] = []
    degrees: int = 1
    total_nodes: int = 0
    total_edges: int = 0
    is_truncated: bool = False
    last_fetched_at: Optional[datetime] = None
    warning: Optional[str] = None


class ShortestPathResponse(BaseModel):
    source_id: str
    target_id: str
    max_degrees: int
    found: bool
    length: Optional[int] = None
    path_nodes: List[VerifiedNodeSchema] = []
    path_edges: List[VerifiedEdgeSchema] = []
    message: Optional[str] = None


# --- Financials & Dossier Schemas ---

class NodeFinancialsSchema(BaseModel):
    id: str
    fiscal_year: int
    annual_revenue: float
    currency: str = "EUR"
    filing_type: str
    filing_date: Optional[str] = None
    source_citation: Optional[SourceCitationSchema] = None

    model_config = ConfigDict(from_attributes=True)


class ItalianContractSchema(BaseModel):
    id: str
    cig: str
    contract_title: str
    awarded_amount: float
    currency: str = "EUR"
    award_date: Optional[str] = None
    contracting_authority: Optional[str] = None
    source_citation: Optional[SourceCitationSchema] = None

    model_config = ConfigDict(from_attributes=True)


class CompanyDossierResponse(BaseModel):
    node: VerifiedNodeSchema
    financials: List[NodeFinancialsSchema] = []
    contracts: List[ItalianContractSchema] = []
    officers: List[VerifiedNodeSchema] = []
    citations: List[SourceCitationSchema] = []
    last_fetched_at: datetime
    missing_data_notices: List[str] = []


class SearchItem(BaseModel):
    id: str
    node_type: str
    name: str
    jurisdiction: Optional[str] = None
    company_number: Optional[str] = None
    status: Optional[str] = None
    source_publisher: Optional[str] = None


class SearchResponse(BaseModel):
    query: str
    total: int
    results: List[SearchItem]
