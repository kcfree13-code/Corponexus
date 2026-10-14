import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/graph_provider.dart';
import '../../widgets/obsidian_card.dart';
import '../graph/graph_canvas_screen.dart';
import '../pathfinder/pathfinder_screen.dart';
import '../globe/globe_view_screen.dart';
import '../history/time_machine_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.search(query.trim());
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(res['results'] ?? []);
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub, color: ObsidianTheme.neonCyan),
            SizedBox(width: 10),
            Text("CORPNEXUS INTELLIGENCE"),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Header
              const Text(
                "Esplorazione e Bonifica Dati Societari",
                style: TextStyle(
                  color: ObsidianTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Database Permanente Certificato & Integrazione Ufficiale",
                style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: ObsidianTheme.textPrimary),
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: "Cerca azienda o amministratore (es. Nexus Tech, Mario Rossi)...",
                  hintStyle: const TextStyle(color: ObsidianTheme.textDim, fontSize: 13),
                  filled: true,
                  fillColor: ObsidianTheme.surfaceGlass,
                  prefixIcon: const Icon(Icons.search, color: ObsidianTheme.neonCyan),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTheme.neonCyan),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward, color: ObsidianTheme.neonCyan),
                          onPressed: () => _performSearch(_searchController.text),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ObsidianTheme.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ObsidianTheme.neonCyan),
                  ),
                ),
              ),

              // Search Results (if any)
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Risultati Trovati:",
                  style: TextStyle(color: ObsidianTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final item = _searchResults[index];
                    final isComp = item['node_type'] == 'company';
                    return ObsidianCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      borderColor: isComp ? ObsidianTheme.neonCyan : ObsidianTheme.neonAmber,
                      onTap: () {
                        ref.read(graphProvider.notifier).loadEntity(item['id'], degrees: 1);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GraphCanvasScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            isComp ? Icons.business : Icons.person,
                            color: isComp ? ObsidianTheme.neonCyan : ObsidianTheme.neonAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ObsidianTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${item['id']} • ${item['status'] ?? 'N/D'}",
                                  style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: ObsidianTheme.textMuted),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),
              const Text(
                "Suite di Analisi Forense",
                style: TextStyle(
                  color: ObsidianTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Graph Canvas
              _buildFeatureCard(
                title: "Grafo Relazionale 2D Obsidian",
                description: "Mappa reticolare interattiva, espansione di vicinato fino a 3 gradi con protezione 60fps.",
                icon: Icons.hub_outlined,
                accentColor: ObsidianTheme.neonCyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GraphCanvasScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 2. Shortest Path Finder
              _buildFeatureCard(
                title: "Pathfinder & Verifica Interferenze",
                description: "Ricerca bidirezionale (BFS O(B^(D/2))) tra due soggetti da 1 a 6 gradi con zero chiamate API.",
                icon: Icons.alt_route,
                accentColor: ObsidianTheme.neonAmber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PathfinderScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 3. 3D Globe
              _buildFeatureCard(
                title: "Mappa 3D Sedi & Connessioni Estere",
                description: "Visualizzazione geografica delle sedi legali geocodificate e archi societari transfrontalieri.",
                icon: Icons.public,
                accentColor: ObsidianTheme.neonPurple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlobeViewScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 4. Time Machine
              _buildFeatureCard(
                title: "Time-Machine: Estrazione per Data",
                description: "Filtra il grafo mostrando solo cariche e società attive a una data storica certificata.",
                icon: Icons.history,
                accentColor: ObsidianTheme.neonGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimeMachineScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return ObsidianCard(
      onTap: onTap,
      borderColor: ObsidianTheme.borderSubtle,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.4)),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: ObsidianTheme.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: ObsidianTheme.textDim),
        ],
      ),
    );
  }
}
