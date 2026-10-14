import 'graph_node.dart';
import 'source_citation.dart';

class NodeFinancial {
  final int fiscalYear;
  final double annualRevenue;
  final String currency;
  final String filingType;
  final String? filingDate;
  final SourceCitation? sourceCitation;

  NodeFinancial({
    required this.fiscalYear,
    required this.annualRevenue,
    required this.currency,
    required this.filingType,
    this.filingDate,
    this.sourceCitation,
  });

  factory NodeFinancial.fromJson(Map<String, dynamic> json) {
    return NodeFinancial(
      fiscalYear: json['fiscal_year'] ?? 0,
      annualRevenue: (json['annual_revenue'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EUR',
      filingType: json['filing_type'] ?? 'Bilancio',
      filingDate: json['filing_date'],
      sourceCitation: json['source_citation'] != null
          ? SourceCitation.fromJson(json['source_citation'])
          : null,
    );
  }
}

class ItalianContract {
  final String cig;
  final String contractTitle;
  final double awardedAmount;
  final String currency;
  final String? awardDate;
  final String? contractingAuthority;
  final SourceCitation? sourceCitation;

  ItalianContract({
    required this.cig,
    required this.contractTitle,
    required this.awardedAmount,
    required this.currency,
    this.awardDate,
    this.contractingAuthority,
    this.sourceCitation,
  });

  factory ItalianContract.fromJson(Map<String, dynamic> json) {
    return ItalianContract(
      cig: json['cig'] ?? '',
      contractTitle: json['contract_title'] ?? '',
      awardedAmount: (json['awarded_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EUR',
      awardDate: json['award_date'],
      contractingAuthority: json['contracting_authority'],
      sourceCitation: json['source_citation'] != null
          ? SourceCitation.fromJson(json['source_citation'])
          : null,
    );
  }
}

class CompanyDossier {
  final GraphNode node;
  final List<NodeFinancial> financials;
  final List<ItalianContract> contracts;
  final List<GraphNode> officers;
  final List<SourceCitation> citations;
  final DateTime lastFetchedAt;
  final List<String> missingDataNotices;

  CompanyDossier({
    required this.node,
    required this.financials,
    required this.contracts,
    required this.officers,
    required this.citations,
    required this.lastFetchedAt,
    required this.missingDataNotices,
  });

  factory CompanyDossier.fromJson(Map<String, dynamic> json) {
    return CompanyDossier(
      node: GraphNode.fromJson(json['node']),
      financials: (json['financials'] as List? ?? [])
          .map((f) => NodeFinancial.fromJson(f))
          .toList(),
      contracts: (json['contracts'] as List? ?? [])
          .map((c) => ItalianContract.fromJson(c))
          .toList(),
      officers: (json['officers'] as List? ?? [])
          .map((o) => GraphNode.fromJson(o))
          .toList(),
      citations: (json['citations'] as List? ?? [])
          .map((c) => SourceCitation.fromJson(c))
          .toList(),
      lastFetchedAt: DateTime.tryParse(json['last_fetched_at'] ?? '') ?? DateTime.now(),
      missingDataNotices: List<String>.from(json['missing_data_notices'] ?? []),
    );
  }
}
