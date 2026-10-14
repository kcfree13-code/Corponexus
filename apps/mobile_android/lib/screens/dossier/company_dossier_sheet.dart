import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/company_dossier.dart';
import '../../widgets/obsidian_card.dart';
import '../../widgets/source_provenance_sheet.dart';

class CompanyDossierSheet extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDossierSheet({super.key, required this.companyId});

  static void show(BuildContext context, String companyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObsidianTheme.surfaceGlass,
      builder: (ctx) => CompanyDossierSheet(companyId: companyId),
    );
  }

  @override
  ConsumerState<CompanyDossierSheet> createState() => _CompanyDossierSheetState();
}

class _CompanyDossierSheetState extends ConsumerState<CompanyDossierSheet> {
  CompanyDossier? _dossier;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDossier();
  }

  void _fetchDossier() async {
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getCompanyDossier(widget.companyId);
      setState(() {
        _dossier = CompanyDossier.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Errore durante il recupero del dossier: $e";
        _isLoading = false;
      });
    }
  }

  void _exportJson() {
    if (_dossier == null) return;
    final jsonStr = jsonEncode({
      "company": _dossier!.node.name,
      "id": _dossier!.node.id,
      "status": _dossier!.node.status,
      "financials": _dossier!.financials.map((f) => {"fy": f.fiscalYear, "revenue": f.annualRevenue}).toList(),
      "contracts": _dossier!.contracts.map((c) => {"cig": c.cig, "amount": c.awardedAmount}).toList(),
      "last_fetched_at": _dossier!.lastFetchedAt.toIso8601String(),
    });
    Share.share(jsonStr, subject: "CorpNexus Dossier - ${_dossier!.node.name}");
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 0);
    final df = DateFormat('dd/MM/yyyy alle HH:mm');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ObsidianTheme.neonCyan))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: ObsidianTheme.alertRed)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dossier!.node.name,
                                  style: const TextStyle(
                                    color: ObsidianTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_dossier!.node.jurisdiction?.toUpperCase() ?? 'N/D'} • N. REA/Reg: ${_dossier!.node.companyNumber ?? 'N/D'}",
                                  style: const TextStyle(color: ObsidianTheme.neonCyan, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: ObsidianTheme.neonCyan),
                            onPressed: _exportJson,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: ObsidianTheme.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Dati rilevati il: ${df.format(_dossier!.lastFetchedAt)}",
                        style: const TextStyle(color: ObsidianTheme.textDim, fontSize: 11),
                      ),
                      const Divider(color: ObsidianTheme.borderSubtle, height: 24),

                      // Certified 5-Year Revenue Section
                      const Text(
                        "Ricavi Annuali Certificati (5 Anni)",
                        style: TextStyle(
                          color: ObsidianTheme.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Dati estratti direttamente da bilanci ufficiali (10-K / Registri Nazionali). Zero stime.",
                        style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 14),

                      if (_dossier!.financials.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ObsidianTheme.obsidianBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ObsidianTheme.borderSubtle),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: ObsidianTheme.neonAmber, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Dato non disponibile nei registri ufficiali",
                                  style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // FL_CHART Bar Chart
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              barGroups: _dossier!.financials.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.value.fiscalYear,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.annualRevenue / 1000000, // Millions
                                      color: ObsidianTheme.neonCyan,
                                      width: 14,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) => Text(
                                      "${val.toInt()}",
                                      style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 10),
                                    ),
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 34,
                                    getTitlesWidget: (val, meta) => Text(
                                      "${val.toInt()}M",
                                      style: const TextStyle(color: ObsidianTheme.textDim, fontSize: 10),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ANAC Italian Public Procurement Contracts
                      const Text(
                        "Appalti Pubblici & Contratti ANAC (OCDS)",
                        style: TextStyle(
                          color: ObsidianTheme.neonAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_dossier!.contracts.isEmpty) ...[
                        const Text(
                          "Nessun appalto registrato nei dati aperti ANAC.",
                          style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dossier!.contracts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final contract = _dossier!.contracts[index];
                            return ObsidianCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "CIG: ${contract.cig}",
                                        style: const TextStyle(
                                          color: ObsidianTheme.neonAmber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        currencyFmt.format(contract.awardedAmount),
                                        style: const TextStyle(
                                          color: ObsidianTheme.neonGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    contract.contractTitle,
                                    style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 12),
                                  ),
                                  if (contract.contractingAuthority != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "Stazione Appaltante: ${contract.contractingAuthority}",
                                      style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Bottom "Fonti Ufficiali" Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.verified, color: ObsidianTheme.neonCyan),
                          label: Text(
                            "ISPEZIONA FONTI UFFICIALI (${_dossier!.citations.length})",
                            style: const TextStyle(letterSpacing: 1.0),
                          ),
                          onPressed: () {
                            SourceProvenanceSheet.show(context, _dossier!.citations);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
