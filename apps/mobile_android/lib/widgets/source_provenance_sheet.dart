import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/source_citation.dart';

class SourceProvenanceSheet extends StatelessWidget {
  final List<SourceCitation> citations;

  const SourceProvenanceSheet({super.key, required this.citations});

  static void show(BuildContext context, List<SourceCitation> citations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObsidianTheme.surfaceGlass,
      builder: (ctx) => SourceProvenanceSheet(citations: citations),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: ObsidianTheme.neonCyan, size: 24),
              const SizedBox(width: 10),
              const Text(
                "Fonti Ufficiali e Provenienza",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ObsidianTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: ObsidianTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Politica di Integrità e Zero Deduzioni: ogni entità, relazione e bilancio archiviato è direttamente tracciabile a un registro ufficiale.",
            style: TextStyle(fontSize: 13, color: ObsidianTheme.textMuted),
          ),
          const Divider(color: ObsidianTheme.borderSubtle, height: 24),
          Expanded(
            child: citations.isEmpty
                ? const Center(
                    child: Text(
                      "Nessuna fonte registrata",
                      style: TextStyle(color: ObsidianTheme.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: citations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final cit = citations[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ObsidianTheme.obsidianBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ObsidianTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cit.sourcePublisher,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ObsidianTheme.neonCyan,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  df.format(cit.retrievedAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ObsidianTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (cit.filingId != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Protocollo / Atto: ${cit.filingId}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ObsidianTheme.textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(cit.sourceUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.open_in_new, size: 14, color: ObsidianTheme.neonCyan),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      cit.sourceUrl,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ObsidianTheme.neonCyan,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
