import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, ForeignKey, Text, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


def utc_now():
    return datetime.now(timezone.utc)


class SourceCitation(Base):
    __tablename__ = "source_citations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    source_publisher = Column(String(100), nullable=False)  # OpenCorporates, SEC EDGAR, INSEE, ANAC, etc.
    source_url = Column(Text, nullable=False)
    filing_id = Column(String(120), nullable=True)
    retrieved_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    raw_response_snippet = Column(Text, nullable=True)

    # Relationships
    nodes = relationship("VerifiedNode", back_populates="source_citation", cascade="all")
    edges = relationship("VerifiedEdge", back_populates="source_citation", cascade="all")
    financials = relationship("NodeFinancials", back_populates="source_citation", cascade="all")
    contracts = relationship("ItalianPublicContract", back_populates="source_citation", cascade="all")


class UserLegalConsent(Base):
    __tablename__ = "user_legal_consents"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(64), nullable=False, index=True)
    terms_version = Column(String(50), default="v1.0-2026-10", nullable=False)
    clause_1_byok_accepted = Column(Boolean, nullable=False)
    clause_2_shared_cache_accepted = Column(Boolean, nullable=False)
    clause_3_zero_inference_disclaimer_accepted = Column(Boolean, nullable=False)
    accepted_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    client_ip_hash = Column(String(64), nullable=False)  # SHA-256 hash of client IP
    app_platform = Column(String(50), default="Android Flutter", nullable=False)


class VerifiedNode(Base):
    __tablename__ = "verified_nodes"

    id = Column(String(120), primary_key=True)  # e.g., "company:it:01234567890", "person:john-doe"
    node_type = Column(String(50), nullable=False)  # "company", "officer", "beneficial_owner"
    name = Column(String(255), nullable=False, index=True)
    jurisdiction = Column(String(50), nullable=True, index=True)
    company_number = Column(String(100), nullable=True, index=True)
    status = Column(String(100), nullable=True)
    incorporation_date = Column(String(20), nullable=True)  # ISO Date YYYY-MM-DD
    dissolution_date = Column(String(20), nullable=True)
    registered_address_in_full = Column(Text, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    last_fetched_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    source_citation_id = Column(String(36), ForeignKey("source_citations.id"), nullable=False)
    source_citation = relationship("SourceCitation", back_populates="nodes")

    # Edges from and to this node
    out_edges = relationship("VerifiedEdge", foreign_keys="VerifiedEdge.source_node_id", back_populates="source_node", cascade="all, delete-orphan")
    in_edges = relationship("VerifiedEdge", foreign_keys="VerifiedEdge.target_node_id", back_populates="target_node", cascade="all, delete-orphan")
    
    # Financials and contracts
    financials = relationship("NodeFinancials", back_populates="node", cascade="all, delete-orphan")
    contracts = relationship("ItalianPublicContract", back_populates="node", cascade="all, delete-orphan")
    snapshots = relationship("HistoricalSnapshot", back_populates="node", cascade="all, delete-orphan")


class VerifiedEdge(Base):
    __tablename__ = "verified_edges"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    source_node_id = Column(String(120), ForeignKey("verified_nodes.id"), nullable=False, index=True)
    target_node_id = Column(String(120), ForeignKey("verified_nodes.id"), nullable=False, index=True)
    relationship_type = Column(String(80), nullable=False)  # "officer_of", "director_of", "shareholder_of", "ultimate_beneficial_owner_of", "parent_company_of", "subsidiary_of"
    start_date = Column(String(20), nullable=True)  # YYYY-MM-DD
    end_date = Column(String(20), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    ownership_percentage = Column(Float, nullable=True)
    last_fetched_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    source_citation_id = Column(String(36), ForeignKey("source_citations.id"), nullable=False)
    source_citation = relationship("SourceCitation", back_populates="edges")

    source_node = relationship("VerifiedNode", foreign_keys=[source_node_id], back_populates="out_edges")
    target_node = relationship("VerifiedNode", foreign_keys=[target_node_id], back_populates="in_edges")


class NodeFinancials(Base):
    __tablename__ = "node_financials"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    node_id = Column(String(120), ForeignKey("verified_nodes.id"), nullable=False, index=True)
    fiscal_year = Column(Integer, nullable=False, index=True)
    annual_revenue = Column(Float, nullable=False)
    currency = Column(String(10), default="EUR", nullable=False)
    filing_type = Column(String(50), nullable=False)  # "10-K", "20-F", "Bilancio Ufficiale"
    filing_date = Column(String(20), nullable=True)

    source_citation_id = Column(String(36), ForeignKey("source_citations.id"), nullable=False)
    source_citation = relationship("SourceCitation", back_populates="financials")
    node = relationship("VerifiedNode", back_populates="financials")


class HistoricalSnapshot(Base):
    __tablename__ = "historical_snapshots"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    entity_id = Column(String(120), ForeignKey("verified_nodes.id"), nullable=False, index=True)
    snapshot_timestamp = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    snapshot_payload = Column(Text, nullable=False)  # JSON representation of node + connected edges
    reason = Column(String(100), default="pre_refresh_archive", nullable=False)

    node = relationship("VerifiedNode", back_populates="snapshots")


class ItalianPublicContract(Base):
    __tablename__ = "italian_public_contracts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    company_node_id = Column(String(120), ForeignKey("verified_nodes.id"), nullable=False, index=True)
    cig = Column(String(30), nullable=False, index=True)  # Codice Identificativo Gara
    contract_title = Column(Text, nullable=False)
    awarded_amount = Column(Float, nullable=False)
    currency = Column(String(10), default="EUR", nullable=False)
    award_date = Column(String(20), nullable=True)
    contracting_authority = Column(Text, nullable=True)

    source_citation_id = Column(String(36), ForeignKey("source_citations.id"), nullable=False)
    source_citation = relationship("SourceCitation", back_populates="contracts")
    node = relationship("VerifiedNode", back_populates="contracts")


class GeocodedAddress(Base):
    __tablename__ = "geocoded_addresses"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    address_hash = Column(String(64), unique=True, index=True, nullable=False)
    raw_address = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    geocoded_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
