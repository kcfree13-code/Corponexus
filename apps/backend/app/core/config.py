from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "CorpNexus Backend"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5434/corponexus"
    
    # Security & Audit
    TERMS_VERSION: str = "v1.0-2026-10"
    
    # Official Open Data Integrations
    SEC_USER_AGENT: str = "CorpNexus CorporateIntelligence/1.0 (contact: compliance@corponexus.org)"
    NOMINATIM_USER_AGENT: str = "CorpNexus Geocoder/1.0 (contact: info@corponexus.org)"
    OPENCORPORATES_API_BASE: str = "https://api.opencorporates.com/v0.4"
    OPENCORPORATES_DEFAULT_TOKEN: str = ""
    OPENOWNERSHIP_API_BASE: str = "https://register.openownership.org/api/v1"
    INSEE_SIRENE_API_BASE: str = "https://api.insee.fr/entreprises/sirene/V3.11"
    WIKIDATA_SPARQL_ENDPOINT: str = "https://query.wikidata.org/sparql"
    ANAC_OCDS_API_BASE: str = "https://dati.anticorruzione.it/opendata/api/v1"

    # CORS
    CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
