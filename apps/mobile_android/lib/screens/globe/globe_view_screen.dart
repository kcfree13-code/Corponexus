import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/graph_provider.dart';
import '../../models/graph_node.dart';
import '../dossier/company_dossier_sheet.dart';

class GlobeViewScreen extends ConsumerWidget {
  const GlobeViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphState = ref.watch(graphProvider);
    final geoNodes = graphState.nodes
        .where((n) => n.latitude != null && n.longitude != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("MAPPA 3D SEDI & ARCHI ESTERI"),
      ),
      body: Stack(
        children: [
          // Globe Background Visualizer
          Container(
            color: ObsidianTheme.obsidianBackground,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stylized Globe Radar Circle
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ObsidianTheme.neonCyan.withOpacity(0.3), width: 1.5),
                      gradient: RadialGradient(
                        colors: [
                          ObsidianTheme.neonCyan.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ObsidianTheme.neonPurple.withOpacity(0.2), width: 1),
                    ),
                  ),
                  const Icon(Icons.public, size: 80, color: ObsidianTheme.borderGlow),
                ],
              ),
            ),
          ),

          // Verified Headquarters List with Lat/Lon Coordinates
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: ObsidianTheme.surfaceGlass.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ObsidianTheme.borderGlow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sedi Legali Geocodificate (Nominatim)",
                        style: TextStyle(
                          color: ObsidianTheme.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ObsidianTheme.neonCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ObsidianTheme.neonCyan),
                        ),
                        child: Text(
                          "${geoNodes.length} SEDI",
                          style: const TextStyle(
                            color: ObsidianTheme.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: geoNodes.isEmpty
                        ? const Center(
                            child: Text(
                              "Nessuna sede con coordinate verificate trovata nel grafo corrente.",
                              style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            itemCount: geoNodes.length,
                            separatorBuilder: (_, __) => const Divider(color: ObsidianTheme.borderSubtle),
                            itemBuilder: (ctx, index) {
                              final node = geoNodes[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.location_on, color: ObsidianTheme.neonCyan),
                                title: Text(
                                  node.name,
                                  style: const TextStyle(
                                    color: ObsidianTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  "${node.registeredAddress ?? 'Indirizzo N/D'}\nLat: ${node.latitude!.toStringAsFixed(4)}, Lon: ${node.longitude!.toStringAsFixed(4)}",
                                  style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.assignment_outlined, color: ObsidianTheme.neonCyan, size: 20),
                                  onPressed: () => CompanyDossierSheet.show(context, node.id),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
