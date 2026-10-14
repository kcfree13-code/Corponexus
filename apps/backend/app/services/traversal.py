from typing import Dict, Any, List, Set, Tuple, Optional
import networkx as nx
from app.models import VerifiedNode, VerifiedEdge


class GraphTraversalService:
    @staticmethod
    def build_networkx_graph(nodes: List[VerifiedNode], edges: List[VerifiedEdge]) -> nx.Graph:
        """
        Builds an undirected or multi-graph representation of nodes and edges
        for bidirectional BFS pathfinding and degree analysis.
        """
        G = nx.Graph()
        for node in nodes:
            G.add_node(
                node.id,
                name=node.name,
                node_type=node.node_type,
                jurisdiction=node.jurisdiction,
                company_number=node.company_number,
                status=node.status,
                last_fetched_at=node.last_fetched_at
            )

        for edge in edges:
            G.add_edge(
                edge.source_node_id,
                edge.target_node_id,
                id=edge.id,
                relationship_type=edge.relationship_type,
                start_date=edge.start_date,
                end_date=edge.end_date,
                is_active=edge.is_active,
                ownership_percentage=edge.ownership_percentage,
                source_citation_id=edge.source_citation_id
            )
        return G

    @classmethod
    def find_shortest_path_bidirectional(
        cls,
        nodes: List[VerifiedNode],
        edges: List[VerifiedEdge],
        source_id: str,
        target_id: str,
        max_degrees: int = 6
    ) -> Tuple[bool, List[str], List[str]]:
        """
        Executes Bidirectional Breadth-First Search (Bidirectional BFS) in NetworkX
        over the PostgreSQL local graph up to user-selected degree (1..6).
        Reduces complexity from O(B^D) to O(B^{D/2}) with 0 API calls.
        
        Returns:
            (found, path_node_ids, path_edge_ids)
        """
        G = cls.build_networkx_graph(nodes, edges)

        if source_id not in G or target_id not in G:
            return False, [], []

        if source_id == target_id:
            return True, [source_id], []

        try:
            # Bidirectional shortest path
            path = nx.bidirectional_shortest_path(G, source_id, target_id)
            degree_distance = len(path) - 1

            if degree_distance > max_degrees:
                return False, [], []

            # Collect edge IDs corresponding to the path
            path_edge_ids = []
            for u, v in zip(path[:-1], path[1:]):
                edge_data = G.get_edge_data(u, v)
                if edge_data and "id" in edge_data:
                    path_edge_ids.append(edge_data["id"])

            return True, path, path_edge_ids
        except (nx.NetworkXNoPath, nx.NodeNotFound):
            return False, [], []

    @classmethod
    def get_neighborhood(
        cls,
        nodes: List[VerifiedNode],
        edges: List[VerifiedEdge],
        center_id: str,
        degrees: int = 1,
        max_nodes_cap: int = 250
    ) -> Tuple[Set[str], Set[str], bool]:
        """
        Expands node neighborhood up to user degrees (1..3) with a mobile 60fps guardrail
        capping visual canvas at 250 nodes.
        
        Returns:
            (selected_node_ids, selected_edge_ids, is_truncated)
        """
        G = cls.build_networkx_graph(nodes, edges)
        if center_id not in G:
            return set(), set(), False

        # BFS expansion by degrees
        selected_nodes: Set[str] = {center_id}
        current_layer: Set[str] = {center_id}
        visited: Set[str] = {center_id}

        is_truncated = False

        for _ in range(min(degrees, 3)):
            next_layer: Set[str] = set()
            for n in current_layer:
                neighbors = set(G.neighbors(n))
                for neighbor in neighbors:
                    if neighbor not in visited:
                        if len(selected_nodes) >= max_nodes_cap:
                            is_truncated = True
                            break
                        next_layer.add(neighbor)
                        visited.add(neighbor)
                        selected_nodes.add(neighbor)
                if is_truncated:
                    break
            current_layer = next_layer
            if is_truncated or not current_layer:
                break

        # Collect edges between selected nodes
        selected_edges: Set[str] = set()
        subgraph = G.subgraph(selected_nodes)
        for u, v, data in subgraph.edges(data=True):
            if "id" in data:
                selected_edges.add(data["id"])

        return selected_nodes, selected_edges, is_truncated
