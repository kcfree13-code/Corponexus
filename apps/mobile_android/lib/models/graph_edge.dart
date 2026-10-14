import 'source_citation.dart';

class GraphEdge {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String relationshipType;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final double? ownershipPercentage;
  final DateTime lastFetchedAt;
  final SourceCitation? sourceCitation;

  GraphEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.relationshipType,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.ownershipPercentage,
    required this.lastFetchedAt,
    this.sourceCitation,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      id: json['id'] ?? '',
      sourceNodeId: json['source_node_id'] ?? '',
      targetNodeId: json['target_node_id'] ?? '',
      relationshipType: json['relationship_type'] ?? 'collegato_a',
      startDate: json['start_date'],
      endDate: json['end_date'],
      isActive: json['is_active'] ?? true,
      ownershipPercentage: json['ownership_percentage'] != null
          ? (json['ownership_percentage'] as num).toDouble()
          : null,
      lastFetchedAt: DateTime.tryParse(json['last_fetched_at'] ?? '') ?? DateTime.now(),
      sourceCitation: json['source_citation'] != null
          ? SourceCitation.fromJson(json['source_citation'])
          : null,
    );
  }
}
