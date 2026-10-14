import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/graph_node.dart';
import '../models/graph_edge.dart';
import 'auth_provider.dart';

class PathfinderState {
  final String sourceId;
  final String targetId;
  final int maxDegrees;
  final bool isSearching;
  final bool found;
  final int? length;
  final List<GraphNode> pathNodes;
  final List<GraphEdge> pathEdges;
  final String? message;
  final String? error;

  PathfinderState({
    this.sourceId = '',
    this.targetId = '',
    this.maxDegrees = 3,
    this.isSearching = false,
    this.found = false,
    this.length,
    this.pathNodes = const [],
    this.pathEdges = const [],
    this.message,
    this.error,
  });

  PathfinderState copyWith({
    String? sourceId,
    String? targetId,
    int? maxDegrees,
    bool? isSearching,
    bool? found,
    int? length,
    List<GraphNode>? pathNodes,
    List<GraphEdge>? pathEdges,
    String? message,
    String? error,
  }) {
    return PathfinderState(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      maxDegrees: maxDegrees ?? this.maxDegrees,
      isSearching: isSearching ?? this.isSearching,
      found: found ?? this.found,
      length: length ?? this.length,
      pathNodes: pathNodes ?? this.pathNodes,
      pathEdges: pathEdges ?? this.pathEdges,
      message: message ?? this.message,
      error: error,
    );
  }
}

class PathfinderNotifier extends StateNotifier<PathfinderState> {
  final Ref ref;

  PathfinderNotifier(this.ref) : super(PathfinderState());

  void setSource(String id) => state = state.copyWith(sourceId: id);
  void setTarget(String id) => state = state.copyWith(targetId: id);
  void setMaxDegrees(int deg) => state = state.copyWith(maxDegrees: deg);

  Future<void> searchPath() async {
    if (state.sourceId.isEmpty || state.targetId.isEmpty) {
      state = state.copyWith(error: "Seleziona entrambe le entità per avviare l'analisi.");
      return;
    }

    state = state.copyWith(isSearching: true, error: null, found: false);

    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getShortestPath(
        source: state.sourceId,
        target: state.targetId,
        maxDegrees: state.maxDegrees,
      );

      final isFound = data['found'] == true;
      final nodes = (data['path_nodes'] as List? ?? [])
          .map((n) => GraphNode.fromJson(n))
          .toList();
      final edges = (data['path_edges'] as List? ?? [])
          .map((e) => GraphEdge.fromJson(e))
          .toList();

      state = state.copyWith(
        isSearching: false,
        found: isFound,
        length: data['length'],
        pathNodes: nodes,
        pathEdges: edges,
        message: data['message'],
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: "Errore durante la ricerca del percorso: $e",
      );
    }
  }
}

final pathfinderProvider = StateNotifierProvider<PathfinderNotifier, PathfinderState>((ref) {
  return PathfinderNotifier(ref);
});
