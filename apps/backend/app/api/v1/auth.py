import hashlib
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import UserLegalConsent
from app.schemas import ConsentRequest, ConsentResponse, VerifyKeyRequest, VerifyKeyResponse
from app.connectors.opencorporates import OpenCorporatesConnector
from app.core.config import settings

router = APIRouter(prefix="/auth", tags=["Authentication & Legal Consent"])


def hash_ip(ip: str) -> str:
    """Computes SHA-256 of IP address for legal proof without storing raw PII"""
    return hashlib.sha256(ip.encode("utf-8")).hexdigest()


@router.post("/consent", response_model=ConsentResponse, status_code=status.HTTP_201_CREATED)
async def register_user_consent(
    payload: ConsentRequest,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Registers user acceptance of BYOK and Data Integrity legal terms.
    Strictly requires all 3 clauses to be True.
    """
    if not (payload.clause_1_byok_accepted and payload.clause_2_shared_cache_accepted and payload.clause_3_zero_inference_disclaimer_accepted):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tutte le tre clausole legali devono essere esplicitamente accettate per procedere."
        )

    # Extract client IP
    client_ip = request.client.host if request.client else "127.0.0.1"
    ip_hash = hash_ip(client_ip)
    user_id = payload.user_id or str(uuid.uuid4())

    consent = UserLegalConsent(
        user_id=user_id,
        terms_version=payload.terms_version or settings.TERMS_VERSION,
        clause_1_byok_accepted=payload.clause_1_byok_accepted,
        clause_2_shared_cache_accepted=payload.clause_2_shared_cache_accepted,
        clause_3_zero_inference_disclaimer_accepted=payload.clause_3_zero_inference_disclaimer_accepted,
        client_ip_hash=ip_hash,
        app_platform=payload.app_platform
    )
    db.add(consent)
    await db.commit()
    await db.refresh(consent)

    return ConsentResponse(
        id=consent.id,
        user_id=consent.user_id,
        status="accepted",
        accepted_at=consent.accepted_at,
        terms_version=consent.terms_version,
        client_ip_hash=consent.client_ip_hash
    )


@router.post("/verify-key", response_model=VerifyKeyResponse)
async def verify_api_key(payload: VerifyKeyRequest):
    """
    Validates the user's personal API key against the provider registry.
    """
    if payload.provider == "opencorporates":
        connector = OpenCorporatesConnector(api_token=payload.api_key)
        is_valid = await connector.verify_token()
        msg = "API Key OpenCorporates verificata con successo." if is_valid else "API Key non valida o quota esaurita."
        return VerifyKeyResponse(provider="opencorporates", is_valid=is_valid, message=msg)
    elif payload.provider == "insee":
        # Format check for INSEE SIRENE token
        is_valid = len(payload.api_key.strip()) > 10
        msg = "Token INSEE SIRENE registrato." if is_valid else "Token INSEE SIRENE non valido."
        return VerifyKeyResponse(provider="insee", is_valid=is_valid, message=msg)
    else:
        raise HTTPException(status_code=400, detail=f"Fornitore {payload.provider} non supportato.")
