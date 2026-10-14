import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/graph_node.dart';
import '../models/graph_edge.dart';
import 'auth_provider.dart';

class GraphState {
  final String? centerNodeId;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final int degrees;
  final bool isTruncated;
  final DateTime? lastFetchedAt;
  final bool isLoading;
  final bool isRefreshing;
  final String? warningMessage;
  final String? errorMessage;

  GraphState({
    this.centerNodeId,
    this.nodes = const [],
    this.edges = const [],
    this.degrees = 1,
    this.isTruncated = false,
    this.lastFetchedAt,
    this.isLoading = false,
    this.isRefreshing = false,
    this.warningMessage,
    this.errorMessage,
  });

  GraphState copyWith({
    String? centerNodeId,
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
    int? degrees,
    bool? isTruncated,
    DateTime? lastFetchedAt,
    bool? isLoading,
    bool? isRefreshing,
    String? warningMessage,
    String? errorMessage,
  }) {
    return GraphState(
      centerNodeId: centerNodeId ?? this.centerNodeId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      degrees: degrees ?? this.degrees,
      isTruncated: isTruncated ?? this.isTruncated,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      warningMessage: warningMessage,
      errorMessage: errorMessage,
    );
  }
}

class GraphNotifier extends StateNotifier<GraphState> {
  final Ref ref;

  GraphNotifier(this.ref) : super(GraphState());

  Future<void> loadEntity(String entityId, {int? degrees}) async {
    final deg = degrees ?? state.degrees;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getEntityGraph(entityId, degrees: deg);

      final nodesList = (data['nodes'] as List? ?? [])
          .map((n) => GraphNode.fromJson(n))
          .toList();
      final edgesList = (data['edges'] as List? ?? [])
          .map((e) => GraphEdge.fromJson(e))
          .toList();

      state = state.copyWith(
        centerNodeId: entityId,
        nodes: nodesList,
        edges: edgesList,
        degrees: deg,
        isTruncated: data['is_truncated'] == true,
        lastFetchedAt: DateTime.tryParse(data['last_fetched_at'] ?? ''),
        warningMessage: data['warning'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Errore durante il caricamento del grafo: $e",
      );
    }
  }

  Future<void> refreshLive(String entityId) async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.refreshEntityLive(entityId);

      final nodesList = (data['nodes'] as List? ?? [])
          .map((n) => GraphNode.fromJson(n))
          .toList();
      final edgesList = (data['edges'] as List? ?? [])
          .map((e) => GraphEdge.fromJson(e))
          .toList();

      state = state.copyWith(
        nodes: nodesList,
        edges: edgesList,
        lastFetchedAt: DateTime.tryParse(data['last_fetched_at'] ?? ''),
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: "Errore durante l'aggiornamento live: $e",
      );
    }
  }
}

final graphProvider = StateNotifierProvider<GraphNotifier, GraphState>((ref) {
  return GraphNotifier(ref);
});
