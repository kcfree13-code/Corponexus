class SourceCitation {
  final String id;
  final String sourcePublisher;
  final String sourceUrl;
  final String? filingId;
  final DateTime retrievedAt;
  final String? rawResponseSnippet;

  SourceCitation({
    required this.id,
    required this.sourcePublisher,
    required this.sourceUrl,
    this.filingId,
    required this.retrievedAt,
    this.rawResponseSnippet,
  });

  factory SourceCitation.fromJson(Map<String, dynamic> json) {
    return SourceCitation(
      id: json['id'] ?? '',
      sourcePublisher: json['source_publisher'] ?? 'Registro Ufficiale',
      sourceUrl: json['source_url'] ?? '',
      filingId: json['filing_id'],
      retrievedAt: DateTime.tryParse(json['retrieved_at'] ?? '') ?? DateTime.now(),
      rawResponseSnippet: json['raw_response_snippet'],
    );
  }
}
