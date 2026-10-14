from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, Header, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.models import VerifiedNode, VerifiedEdge, SourceCitation
from app.schemas import (
    GraphResponse,
    VerifiedNodeSchema,
    VerifiedEdgeSchema,
    ShortestPathResponse,
    SourceCitationSchema,
)
from app.services.traversal import GraphTraversalService
from app.services.ingestion import IngestionService
from app.connectors.opencorporates import OpenCorporatesConnector

router = APIRouter(prefix="/graph", tags=["Graph & Entity Intelligence"])


@router.get("/entity/{entity_id}", response_model=GraphResponse)
async def get_entity_graph(
    entity_id: str,
    degrees: int = Query(1, ge=1, le=3, description="Degree of separation for neighborhood expansion (1..3)"),
    x_api_key: Optional[str] = Header(None, description="Personal OpenCorporates API Key (BYOK)"),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns entity and its connected neighborhood from permanent PostgreSQL cache.
    Zero Unnecessary API Calls: If entity exists, serves from DB immediately (0 API calls).
    If entity is completely absent from DB and X-API-Key is provided, performs live 1st-degree fetch.
    """
    # 1. Check if node exists in DB
    stmt = (
        select(VerifiedNode)
        .where(VerifiedNode.id == entity_id)
        .options(selectinload(VerifiedNode.source_citation))
    )
    res = await db.execute(stmt)
    node = res.scalars().first()

    # If absent and API key provided, attempt live 1st degree fetch
    if not node and x_api_key:
        parts = entity_id.split(":")
        if len(parts) >= 3 and parts[0] == "company":
            jurisdiction = parts[1]
            company_num = parts[2]
            connector = OpenCorporatesConnector(api_token=x_api_key)
            raw_comp = await connector.get_company_details(jurisdiction, company_num)
            if raw_comp:
                ingestion = IngestionService(db)
                node = await ingestion.ingest_opencorporates_company(raw_comp, api_token=x_api_key)

    if not node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Entità '{entity_id}' non trovata nel database condiviso. Inserisci una API Key per eseguire l'estrazione live."
        )

    # 2. Fetch all nodes and edges from database for graph traversal
    stmt_nodes = select(VerifiedNode).options(selectinload(VerifiedNode.source_citation))
    all_nodes = (await db.execute(stmt_nodes)).scalars().all()

    stmt_edges = select(VerifiedEdge).options(selectinload(VerifiedEdge.source_citation))
    all_edges = (await db.execute(stmt_edges)).scalars().all()

    # 3. Traverse neighborhood with mobile 250-node cap
    selected_node_ids, selected_edge_ids, is_truncated = GraphTraversalService.get_neighborhood(
        nodes=list(all_nodes),
        edges=list(all_edges),
        center_id=entity_id,
        degrees=degrees,
        max_nodes_cap=250
    )

    filtered_nodes = [n for n in all_nodes if n.id in selected_node_ids]
    filtered_edges = [e for e in all_edges if e.id in selected_edge_ids]

    warning_msg = None
    if is_truncated:
        warning_msg = "Visualizzazione limitata a 250 nodi per preservare la fluidità grafica mobile (60fps)."

    return GraphResponse(
        center_node_id=entity_id,
        nodes=[VerifiedNodeSchema.model_validate(n) for n in filtered_nodes],
        edges=[VerifiedEdgeSchema.model_validate(e) for e in filtered_edges],
        degrees=degrees,
        total_nodes=len(filtered_nodes),
        total_edges=len(filtered_edges),
        is_truncated=is_truncated,
        last_fetched_at=node.last_fetched_at,
        warning=warning_msg
    )


@router.post("/refresh/{entity_id}", response_model=GraphResponse)
async def refresh_entity_live(
    entity_id: str,
    x_api_key: str = Header(..., description="Personal OpenCorporates API Key required for live refresh"),
    db: AsyncSession = Depends(get_db)
):
    """
    Explicit user-triggered live re-fetch.
    Archives previous state into historical_snapshots and updates last_fetched_at.
    Consumes 1 external API call from user's personal key.
    """
    parts = entity_id.split(":")
    if len(parts) < 3 or parts[0] != "company":
        raise HTTPException(status_code=400, detail="Aggiornamento supportato solo per entità di tipo company.")

    jurisdiction = parts[1]
    company_num = parts[2]

    connector = OpenCorporatesConnector(api_token=x_api_key)
    raw_comp = await connector.get_company_details(jurisdiction, company_num)
    if not raw_comp:
        raise HTTPException(
            status_code=502,
            detail="Impossibile recuperare i dati aggiornati dal registro ufficiale OpenCorporates."
        )

    ingestion = IngestionService(db)
    refreshed_node = await ingestion.ingest_opencorporates_company(raw_comp, api_token=x_api_key)

    # Return refreshed 1-degree graph
    return await get_entity_graph(entity_id=refreshed_node.id, degrees=1, x_api_key=None, db=db)


@router.get("/shortest-path", response_model=ShortestPathResponse)
async def find_shortest_path(
    source: str = Query(..., description="Source entity ID"),
    target: str = Query(..., description="Target entity ID"),
    max_degrees: int = Query(6, ge=1, le=6, description="Degree of separation limit (1..6)"),
    db: AsyncSession = Depends(get_db)
):
    """
    Runs Bidirectional Breadth-First Search (Bidirectional BFS) in NetworkX
    over the PostgreSQL local graph up to user-selected degree (1..6).
    Complexity O(B^{D/2}), 0 external API calls.
    """
    stmt_nodes = select(VerifiedNode).options(selectinload(VerifiedNode.source_citation))
    all_nodes = (await db.execute(stmt_nodes)).scalars().all()

    stmt_edges = select(VerifiedEdge).options(selectinload(VerifiedEdge.source_citation))
    all_edges = (await db.execute(stmt_edges)).scalars().all()

    found, path_node_ids, path_edge_ids = GraphTraversalService.find_shortest_path_bidirectional(
        nodes=list(all_nodes),
        edges=list(all_edges),
        source_id=source,
        target_id=target,
        max_degrees=max_degrees
    )

    if not found:
        return ShortestPathResponse(
            source_id=source,
            target_id=target,
            max_degrees=max_degrees,
            found=False,
            message=f"Nessun collegamento documentato entro {max_degrees} gradi di separazione nel database."
        )

    path_nodes = [n for n in all_nodes if n.id in path_node_ids]
    # Maintain path order
    nodes_by_id = {n.id: n for n in path_nodes}
    ordered_path_nodes = [nodes_by_id[nid] for nid in path_node_ids if nid in nodes_by_id]
    
    path_edges = [e for e in all_edges if e.id in path_edge_ids]

    return ShortestPathResponse(
        source_id=source,
        target_id=target,
        max_degrees=max_degrees,
        found=True,
        length=len(path_node_ids) - 1,
        path_nodes=[VerifiedNodeSchema.model_validate(n) for n in ordered_path_nodes],
        path_edges=[VerifiedEdgeSchema.model_validate(e) for e in path_edges],
        message="Percorso di collegamento verificato con fonti ufficiali."
    )


@router.get("/historical", response_model=GraphResponse)
async def get_historical_graph(
    entity_id: str,
    date: str = Query(..., pattern=r"^\d{4}-\d{2}-\d{2}$", description="Historical date YYYY-MM-DD"),
    db: AsyncSession = Depends(get_db)
):
    """
    Reconstructs the exact corporate network active on the requested date
    using documented start_date and end_date.
    Zero Inference: if relationship dates are unrecorded, reports as inactive on historical dates.
    """
    stmt_node = (
        select(VerifiedNode)
        .where(VerifiedNode.id == entity_id)
        .options(selectinload(VerifiedNode.source_citation))
    )
    node = (await db.execute(stmt_node)).scalars().first()
    if not node:
        raise HTTPException(status_code=404, detail="Entità non trovata.")

    # Edges connected to this entity active on `date`
    stmt_edges = (
        select(VerifiedEdge)
        .where(
            (VerifiedEdge.source_node_id == entity_id) | (VerifiedEdge.target_node_id == entity_id)
        )
        .options(selectinload(VerifiedEdge.source_citation))
    )
    all_edges = (await db.execute(stmt_edges)).scalars().all()

    active_edges = []
    active_node_ids = {entity_id}

    for e in all_edges:
        is_active_on_date = True
        if e.start_date and e.start_date > date:
            is_active_on_date = False
        if e.end_date and e.end_date < date:
            is_active_on_date = False

        if is_active_on_date:
            active_edges.append(e)
            active_node_ids.add(e.source_node_id)
            active_node_ids.add(e.target_node_id)

    stmt_nodes = (
        select(VerifiedNode)
        .where(VerifiedNode.id.in_(active_node_ids))
        .options(selectinload(VerifiedNode.source_citation))
    )
    nodes = (await db.execute(stmt_nodes)).scalars().all()

    return GraphResponse(
        center_node_id=entity_id,
        nodes=[VerifiedNodeSchema.model_validate(n) for n in nodes],
        edges=[VerifiedEdgeSchema.model_validate(e) for e in active_edges],
        degrees=1,
        total_nodes=len(nodes),
        total_edges=len(active_edges),
        is_truncated=False,
        last_fetched_at=node.last_fetched_at,
        warning=f"Rete societaria attiva alla data storica: {date}"
    )
