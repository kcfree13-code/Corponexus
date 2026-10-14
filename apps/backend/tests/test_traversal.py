import pytest
from app.models import VerifiedNode, VerifiedEdge
from app.services.traversal import GraphTraversalService


def test_bidirectional_bfs_shortest_path():
    # Build synthetic chain of entities: A -> B -> C -> D -> E -> F
    nodes = [
        VerifiedNode(id=f"node-{i}", name=f"Node {i}", node_type="company" if i % 2 == 0 else "officer")
        for i in range(1, 7)
    ]
    edges = [
        VerifiedEdge(id=f"edge-{i}", source_node_id=f"node-{i}", target_node_id=f"node-{i+1}", relationship_type="connects_to")
        for i in range(1, 6)
    ]

    # Test 1: Path from node-1 to node-3 (2 hops) with max_degrees=2
    found, path_nodes, path_edges = GraphTraversalService.find_shortest_path_bidirectional(
        nodes=nodes,
        edges=edges,
        source_id="node-1",
        target_id="node-3",
        max_degrees=2
    )
    assert found is True
    assert path_nodes == ["node-1", "node-2", "node-3"]
    assert len(path_edges) == 2

    # Test 2: Path from node-1 to node-6 (5 hops) with max_degrees=4 -> should fail (exceeds max_degrees)
    found_capped, _, _ = GraphTraversalService.find_shortest_path_bidirectional(
        nodes=nodes,
        edges=edges,
        source_id="node-1",
        target_id="node-6",
        max_degrees=4
    )
    assert found_capped is False

    # Test 3: Path from node-1 to node-6 with max_degrees=6 -> should succeed
    found_ok, path_nodes_6, _ = GraphTraversalService.find_shortest_path_bidirectional(
        nodes=nodes,
        edges=edges,
        source_id="node-1",
        target_id="node-6",
        max_degrees=6
    )
    assert found_ok is True
    assert len(path_nodes_6) == 6


def test_neighborhood_capping_guardrail():
    # Create star network with 300 connected nodes
    center = VerifiedNode(id="center", name="Center Corp", node_type="company")
    nodes = [center]
    edges = []

    for i in range(300):
        n = VerifiedNode(id=f"leaf-{i}", name=f"Leaf {i}", node_type="officer")
        nodes.append(n)
        edges.append(VerifiedEdge(id=f"edge-{i}", source_node_id=f"leaf-{i}", target_node_id="center", relationship_type="officer_of"))

    selected_nodes, selected_edges, is_truncated = GraphTraversalService.get_neighborhood(
        nodes=nodes,
        edges=edges,
        center_id="center",
        degrees=1,
        max_nodes_cap=250
    )

    # Must be strictly capped at 250 nodes for 60fps mobile rendering
    assert len(selected_nodes) == 250
    assert is_truncated is True
