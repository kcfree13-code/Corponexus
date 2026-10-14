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
  bool _hasSearched = false;
  String? _searchError;

  void _performSearch(String query) async {
    final cleanQ = query.trim();
    if (cleanQ.length < 2) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _searchError = "Inserisci almeno 2 caratteri per avviare la ricerca.";
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
      _hasSearched = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.search(cleanQ);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(res['results'] ?? []);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchError = "Impossibile completare la ricerca: verifica la connessione al server.";
      });
    }
  }

  Widget _buildQuickSearchChip(String label) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ObsidianTheme.surfaceGlassHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ObsidianTheme.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 12, color: ObsidianTheme.neonCyan),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
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
                "Database Permanente Certificato & Indice Ufficiale SEC EDGAR",
                style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: ObsidianTheme.textPrimary),
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: "Cerca azienda o amministratore (es. Ferrari, Eni, Apple)...",
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

              // Quick Search Chips
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildQuickSearchChip("Ferrari"),
                  _buildQuickSearchChip("Apple"),
                  _buildQuickSearchChip("Eni"),
                  _buildQuickSearchChip("Stellantis"),
                  _buildQuickSearchChip("Leonardo"),
                  _buildQuickSearchChip("Barilla"),
                  _buildQuickSearchChip("Ferrero"),
                  _buildQuickSearchChip("TIM"),
                  _buildQuickSearchChip("John Elkann"),
                  _buildQuickSearchChip("Mario Rossi"),
                ],
              ),

              // Search Results
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Risultati Trovati (${_searchResults.length}):",
                      style: const TextStyle(color: ObsidianTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _searchResults = [];
                        _hasSearched = false;
                      }),
                      child: const Text("Chiudi", style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 11)),
                    ),
                  ],
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
                    final pub = item['source_publisher'] ?? 'Registro';
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
                                const SizedBox(height: 2),
                                Text(
                                  "${item['id']} • $pub",
                                  style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: ObsidianTheme.neonCyan),
                        ],
                      ),
                    );
                  },
                ),
              ] else if (_hasSearched && !_isSearching && _searchError == null) ...[
                const SizedBox(height: 16),
                ObsidianCard(
                  borderColor: ObsidianTheme.borderSubtle,
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, color: ObsidianTheme.textMuted, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        "Nessun risultato trovato per '${_searchController.text.trim()}'.",
                        style: const TextStyle(color: ObsidianTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "La ricerca interroga il database certificato permanente e l'indice SEC EDGAR. Prova a cliccare su uno dei suggerimenti rapidi sopra o verifica la corretta digitazione.",
                        style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (_searchError != null) ...[
                const SizedBox(height: 16),
                ObsidianCard(
                  borderColor: ObsidianTheme.alertRed,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: ObsidianTheme.alertRed, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _searchError!,
                          style: const TextStyle(color: ObsidianTheme.alertRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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
