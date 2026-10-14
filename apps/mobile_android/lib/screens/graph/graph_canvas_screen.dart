import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/graph_node.dart';
import '../../models/graph_edge.dart';
import '../../providers/graph_provider.dart';
import '../../widgets/degree_slider.dart';
import '../../widgets/live_refresh_dialog.dart';
import '../dossier/company_dossier_sheet.dart';

class GraphCanvasScreen extends ConsumerStatefulWidget {
  const GraphCanvasScreen({super.key});

  @override
  ConsumerState<GraphCanvasScreen> createState() => _GraphCanvasScreenState();
}

class _GraphCanvasScreenState extends ConsumerState<GraphCanvasScreen> {
  final TransformationController _transformController = TransformationController();
  final Map<String, Offset> _nodePositions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(graphProvider);
      if (state.centerNodeId == null) {
        // Load default seed entity for testing if empty
        ref.read(graphProvider.notifier).loadEntity("company:it:01234567890", degrees: 1);
      }
    });
  }

  void _computeLayout(List<GraphNode> nodes, Size canvasSize) {
    if (nodes.isEmpty) return;
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final count = nodes.length;

    // Place center node in the middle
    _nodePositions[nodes.first.id] = center;

    if (count > 1) {
      final radius = min(canvasSize.width, canvasSize.height) * 0.35;
      final angleStep = (2 * pi) / (count - 1);
      for (int i = 1; i < count; i++) {
        final angle = (i - 1) * angleStep;
        _nodePositions[nodes[i].id] = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(graphProvider);
    final df = DateFormat('dd/MM/yyyy alle HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text("GRAFO 2D OBSIDIAN"),
        actions: [
          // Manual Live Refresh Button
          IconButton(
            tooltip: "Richiedi Aggiornamento Live",
            icon: graphState.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTheme.neonCyan),
                  )
                : const Icon(Icons.refresh, color: ObsidianTheme.neonCyan),
            onPressed: graphState.centerNodeId == null || graphState.isRefreshing
                ? null
                : () {
                    LiveRefreshDialog.show(
                      context,
                      graphState.nodes.firstWhere((n) => n.id == graphState.centerNodeId).name,
                      () {
                        ref.read(graphProvider.notifier).refreshLive(graphState.centerNodeId!);
                      },
                    );
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 2D Interactive Force/Physics Canvas
          LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              _computeLayout(graphState.nodes, size);

              if (graphState.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: ObsidianTheme.neonCyan),
                );
              }

              return InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(500),
                minScale: 0.2,
                maxScale: 3.5,
                child: CustomPaint(
                  size: size,
                  painter: GraphPainter(
                    nodes: graphState.nodes,
                    edges: graphState.edges,
                    positions: _nodePositions,
                  ),
                  child: Stack(
                    children: graphState.nodes.map((node) {
                      final pos = _nodePositions[node.id] ?? const Offset(100, 100);
                      return Positioned(
                        left: pos.dx - 24,
                        top: pos.dy - 24,
                        child: GestureDetector(
                          onTap: () {
                            if (node.isCompany) {
                              CompanyDossierSheet.show(context, node.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Amministratore / Esponente: ${node.name}"),
                                  backgroundColor: ObsidianTheme.surfaceGlassHigh,
                                ),
                              );
                            }
                          },
                          child: _buildNodeAvatar(node),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          // Top Floating HUD Badge (Reading timestamp & guardrail warning)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: ObsidianTheme.surfaceGlass.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ObsidianTheme.borderGlow),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: ObsidianTheme.neonCyan, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            graphState.lastFetchedAt != null
                                ? "Dati rilevati il: ${df.format(graphState.lastFetchedAt!)}"
                                : "Dati dal database condiviso",
                            style: const TextStyle(
                              color: ObsidianTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ObsidianTheme.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ObsidianTheme.neonGreen),
                        ),
                        child: const Text(
                          "0 API CALLS",
                          style: TextStyle(
                            color: ObsidianTheme.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (graphState.isTruncated) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ObsidianTheme.neonAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ObsidianTheme.neonAmber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: ObsidianTheme.neonAmber, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            graphState.warningMessage ?? "Visualizzazione limitata a 250 nodi per 60fps.",
                            style: const TextStyle(color: ObsidianTheme.neonAmber, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Controls: Degrees of Separation Slider (1..3)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ObsidianTheme.surfaceGlass.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ObsidianTheme.borderGlow),
              ),
              child: DegreeSlider(
                value: graphState.degrees,
                max: 3, // Guardrail for visual expansion
                onChanged: (newDeg) {
                  if (graphState.centerNodeId != null) {
                    ref.read(graphProvider.notifier).loadEntity(
                          graphState.centerNodeId!,
                          degrees: newDeg,
                        );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeAvatar(GraphNode node) {
    Color nodeColor = ObsidianTheme.neonCyan;
    IconData icon = Icons.business;

    if (node.isOfficer) {
      nodeColor = ObsidianTheme.neonAmber;
      icon = Icons.person;
    } else if (node.isBeneficialOwner) {
      nodeColor = ObsidianTheme.neonPurple;
      icon = Icons.account_balance;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ObsidianTheme.obsidianBackground,
            shape: BoxShape.circle,
            border: Border.all(color: nodeColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: nodeColor.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: nodeColor, size: 24),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ObsidianTheme.surfaceGlass.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            node.name,
            style: const TextStyle(
              color: ObsidianTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Offset> positions;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.positions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = ObsidianTheme.neonCyan.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final p1 = positions[edge.sourceNodeId];
      final p2 = positions[edge.targetNodeId];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
