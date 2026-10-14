import 'source_citation.dart';

class GraphNode {
  final String id;
  final String nodeType; // "company", "officer", "beneficial_owner"
  final String name;
  final String? jurisdiction;
  final String? companyNumber;
  final String? status;
  final String? incorporationDate;
  final String? dissolutionDate;
  final String? registeredAddress;
  final double? latitude;
  final double? longitude;
  final DateTime lastFetchedAt;
  final SourceCitation? sourceCitation;

  GraphNode({
    required this.id,
    required this.nodeType,
    required this.name,
    this.jurisdiction,
    this.companyNumber,
    this.status,
    this.incorporationDate,
    this.dissolutionDate,
    this.registeredAddress,
    this.latitude,
    this.longitude,
    required this.lastFetchedAt,
    this.sourceCitation,
  });

  bool get isCompany => nodeType == 'company';
  bool get isOfficer => nodeType == 'officer';
  bool get isBeneficialOwner => nodeType == 'beneficial_owner';

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'] ?? '',
      nodeType: json['node_type'] ?? 'company',
      name: json['name'] ?? '',
      jurisdiction: json['jurisdiction'],
      companyNumber: json['company_number'],
      status: json['status'],
      incorporationDate: json['incorporation_date'],
      dissolutionDate: json['dissolution_date'],
      registeredAddress: json['registered_address_in_full'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      lastFetchedAt: DateTime.tryParse(json['last_fetched_at'] ?? '') ?? DateTime.now(),
      sourceCitation: json['source_citation'] != null
          ? SourceCitation.fromJson(json['source_citation'])
          : null,
    );
  }
}
