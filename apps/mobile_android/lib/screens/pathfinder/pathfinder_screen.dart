import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/pathfinder_provider.dart';
import '../../widgets/obsidian_card.dart';
import '../../widgets/degree_slider.dart';
import '../../widgets/source_provenance_sheet.dart';

class PathfinderScreen extends ConsumerStatefulWidget {
  const PathfinderScreen({super.key});

  @override
  ConsumerState<PathfinderScreen> createState() => _PathfinderScreenState();
}

class _PathfinderScreenState extends ConsumerState<PathfinderScreen> {
  final TextEditingController _sourceController = TextEditingController(text: "company:it:01234567890");
  final TextEditingController _targetController = TextEditingController(text: "company:it:98765432100");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pathfinderProvider.notifier).setSource(_sourceController.text.trim());
      ref.read(pathfinderProvider.notifier).setTarget(_targetController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathfinderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("PATHFINDER & INTERFERENZE"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              const Text(
                "Ricerca Percorso Minimo & Collegamenti Nascosti",
                style: TextStyle(
                  color: ObsidianTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Algoritmo Bidirectional BFS in NetworkX con complessità O(B^(D/2)) sul grafo locale (0 chiamate API).",
                style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Dual Input Card
              ObsidianCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _sourceController,
                      style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: "Soggetto A (ID o Azienda)",
                        labelStyle: TextStyle(color: ObsidianTheme.neonCyan),
                        prefixIcon: Icon(Icons.circle, color: ObsidianTheme.neonCyan, size: 14),
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (val) => ref.read(pathfinderProvider.notifier).setSource(val.trim()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _targetController,
                      style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: "Soggetto B (ID o Azienda)",
                        labelStyle: TextStyle(color: ObsidianTheme.neonAmber),
                        prefixIcon: Icon(Icons.circle, color: ObsidianTheme.neonAmber, size: 14),
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (val) => ref.read(pathfinderProvider.notifier).setTarget(val.trim()),
                    ),
                    const SizedBox(height: 16),
                    DegreeSlider(
                      value: state.maxDegrees,
                      max: 6,
                      onChanged: (deg) => ref.read(pathfinderProvider.notifier).setMaxDegrees(deg),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: state.isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTheme.obsidianBackground),
                              )
                            : const Icon(Icons.search),
                        label: const Text("VERIFICA COLLEGAMENTI"),
                        onPressed: state.isSearching
                            ? null
                            : () => ref.read(pathfinderProvider.notifier).searchPath(),
                      ),
                    ),
                  ],
                ),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ObsidianTheme.alertRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ObsidianTheme.alertRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: ObsidianTheme.alertRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.error!, style: const TextStyle(color: ObsidianTheme.alertRed, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              // Results Section
              const SizedBox(height: 24),
              if (state.found) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "COLLEGAMENTO IDENTIFICATO (${state.length} GRADI)",
                      style: const TextStyle(
                        color: ObsidianTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ObsidianTheme.neonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ObsidianTheme.neonGreen),
                      ),
                      child: const Text("PROVA UFFICIALE", style: TextStyle(color: ObsidianTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.pathNodes.length,
                  itemBuilder: (ctx, index) {
                    final node = state.pathNodes[index];
                    final isEdgeBelow = index < state.pathEdges.length;
                    final edge = isEdgeBelow ? state.pathEdges[index] : null;

                    return Column(
                      children: [
                        ObsidianCard(
                          borderColor: node.isCompany ? ObsidianTheme.neonCyan : ObsidianTheme.neonAmber,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: node.isCompany
                                    ? ObsidianTheme.neonCyan.withOpacity(0.2)
                                    : ObsidianTheme.neonAmber.withOpacity(0.2),
                                child: Icon(
                                  node.isCompany ? Icons.business : Icons.person,
                                  color: node.isCompany ? ObsidianTheme.neonCyan : ObsidianTheme.neonAmber,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      node.name,
                                      style: const TextStyle(
                                        color: ObsidianTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "${node.nodeType.toUpperCase()} • ${node.id}",
                                      style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (edge != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              onTap: () {
                                if (edge.sourceCitation != null) {
                                  SourceProvenanceSheet.show(context, [edge.sourceCitation!]);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ObsidianTheme.surfaceGlassHigh,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: ObsidianTheme.neonCyan.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.link, size: 16, color: ObsidianTheme.neonCyan),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${edge.relationshipType} (${edge.startDate ?? 'Data N/D'})",
                                      style: const TextStyle(
                                        color: ObsidianTheme.neonCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified, size: 14, color: ObsidianTheme.neonGreen),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ] else if (state.message != null && !state.isSearching) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ObsidianTheme.surfaceGlass,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ObsidianTheme.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      state.message!,
                      style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
