import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/graph_node.dart';
import '../../models/graph_edge.dart';
import '../../widgets/obsidian_card.dart';

class TimeMachineScreen extends ConsumerStatefulWidget {
  const TimeMachineScreen({super.key});

  @override
  ConsumerState<TimeMachineScreen> createState() => _TimeMachineScreenState();
}

class _TimeMachineScreenState extends ConsumerState<TimeMachineScreen> {
  DateTime _selectedDate = DateTime(2020, 1, 1);
  final TextEditingController _entityController = TextEditingController(text: "company:it:01234567890");

  bool _isLoading = false;
  List<GraphNode> _historicalNodes = [];
  List<GraphEdge> _historicalEdges = [];
  String? _statusMessage;

  void _fetchHistoricalData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getHistoricalGraph(
        entityId: _entityController.text.trim(),
        date: dateStr,
      );

      final nodes = (res['nodes'] as List? ?? [])
          .map((n) => GraphNode.fromJson(n))
          .toList();
      final edges = (res['edges'] as List? ?? [])
          .map((e) => GraphEdge.fromJson(e))
          .toList();

      setState(() {
        _historicalNodes = nodes;
        _historicalEdges = edges;
        _statusMessage = res['warning'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Errore durante il recupero dei dati storici: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text("TIME-MACHINE STORICA"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Estrazione Rete Societaria per Data Storica",
                style: TextStyle(
                  color: ObsidianTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Ricostruzione esatta dei soggetti in carica alla data indicata, escludendo cariche cessate o successive.",
                style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Filter Controls
              ObsidianCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _entityController,
                      style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: "ID Entità di Riferimento",
                        labelStyle: TextStyle(color: ObsidianTheme.neonCyan),
                        prefixIcon: Icon(Icons.business, color: ObsidianTheme.neonCyan),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: ObsidianTheme.neonGreen, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Data Storica: ${df.format(_selectedDate)}",
                          style: const TextStyle(
                            color: ObsidianTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(1980),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: const Text("CAMBIA DATA"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTheme.obsidianBackground),
                              )
                            : const Icon(Icons.history_toggle_off),
                        label: const Text("ESTRAI RETE STORICA"),
                        onPressed: _isLoading ? null : _fetchHistoricalData,
                      ),
                    ),
                  ],
                ),
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ObsidianTheme.surfaceGlassHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ObsidianTheme.borderGlow),
                  ),
                  child: Text(_statusMessage!, style: const TextStyle(color: ObsidianTheme.neonCyan, fontSize: 12)),
                ),
              ],

              // Historical Results
              const SizedBox(height: 20),
              if (_historicalNodes.isNotEmpty) ...[
                Text(
                  "SOGGETTI ATTIVI ALLA DATA (${_historicalNodes.length}):",
                  style: const TextStyle(
                    color: ObsidianTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _historicalNodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final node = _historicalNodes[index];
                    return ObsidianCard(
                      borderColor: node.isCompany ? ObsidianTheme.neonCyan : ObsidianTheme.neonAmber,
                      child: Row(
                        children: [
                          Icon(
                            node.isCompany ? Icons.business : Icons.person,
                            color: node.isCompany ? ObsidianTheme.neonCyan : ObsidianTheme.neonAmber,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ObsidianTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${node.nodeType} • Rilevato nei registri",
                                  style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
