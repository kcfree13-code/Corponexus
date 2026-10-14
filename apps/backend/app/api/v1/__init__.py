from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.graph import router as graph_router
from app.api.v1.company import router as company_router
from app.api.v1.search import router as search_router
from app.api.v1.system import router as system_router

api_v1_router = APIRouter()
api_v1_router.include_router(auth_router)
api_v1_router.include_router(graph_router)
api_v1_router.include_router(company_router)
api_v1_router.include_router(search_router)
api_v1_router.include_router(system_router)
