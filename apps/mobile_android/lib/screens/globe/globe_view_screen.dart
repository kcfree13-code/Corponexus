import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../providers/graph_provider.dart';
import '../../models/graph_node.dart';
import '../dossier/company_dossier_sheet.dart';

class GlobeViewScreen extends ConsumerStatefulWidget {
  const GlobeViewScreen({super.key});

  @override
  ConsumerState<GlobeViewScreen> createState() => _GlobeViewScreenState();
}

class _GlobeViewScreenState extends ConsumerState<GlobeViewScreen> {
  final MapController _mapController = MapController();
  GraphNode? _selectedNode;
  bool _isListExpanded = false;

  static const LatLng _italyCenter = LatLng(43.2, 11.8);

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(graphProvider);
    final geoNodes = graphState.nodes
        .where((n) => n.latitude != null && n.longitude != null)
        .toList();

    // Prepare connection polylines between verified headquarters
    final List<Polyline> connectionPolylines = [];
    if (geoNodes.length >= 2) {
      final List<LatLng> points = geoNodes
          .map((n) => LatLng(n.latitude!, n.longitude!))
          .toList();
      connectionPolylines.add(
        Polyline(
          points: points,
          strokeWidth: 3.0,
          color: ObsidianTheme.neonCyan.withOpacity(0.85),
          isDotted: true,
        ),
      );
    }

    return Scaffold(
      backgroundColor: ObsidianTheme.obsidianBackground,
      appBar: AppBar(
        title: const Text("MAPPA FORENSE SEDI & ARCHI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: ObsidianTheme.neonCyan),
            tooltip: "Centra su Italia",
            onPressed: () {
              _mapController.move(_italyCenter, 6.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Real Interactive CartoDB Dark Matter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _italyCenter,
              initialZoom: 6.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              backgroundColor: ObsidianTheme.obsidianBackground,
            ),
            children: [
              // CartoDB Dark Matter Tile Layer (Cyber-Forensic theme)
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'org.corponexus.app',
                maxZoom: 19,
              ),

              // Arcs / Lines connecting headquarters
              if (connectionPolylines.isNotEmpty)
                PolylineLayer(polylines: connectionPolylines),

              // Glowing Markers for each Verified Headquarters
              MarkerLayer(
                markers: geoNodes.map((node) {
                  final isSelected = _selectedNode?.id == node.id;
                  final latLng = LatLng(node.latitude!, node.longitude!);

                  return Marker(
                    point: latLng,
                    width: isSelected ? 120 : 80,
                    height: isSelected ? 80 : 54,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedNode = node);
                        _mapController.move(latLng, 12.0);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ObsidianTheme.surfaceGlass.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? ObsidianTheme.neonAmber : ObsidianTheme.neonCyan,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSelected ? ObsidianTheme.neonAmber : ObsidianTheme.neonCyan).withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              node.name.length > 14 ? "${node.name.substring(0, 12)}.." : node.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? ObsidianTheme.neonAmber : ObsidianTheme.neonCyan,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.location_on,
                            color: isSelected ? ObsidianTheme.neonAmber : ObsidianTheme.neonCyan,
                            size: isSelected ? 34 : 26,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Top Floating Forensic HUD
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ObsidianTheme.surfaceGlass.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ObsidianTheme.borderGlow),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: ObsidianTheme.neonCyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${geoNodes.length} Sedi Legali Verificate (CartoDB Dark / Nominatim)",
                      style: const TextStyle(
                        color: ObsidianTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ObsidianTheme.neonCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ObsidianTheme.neonCyan),
                    ),
                    child: const Text(
                      "LIVE GPS",
                      style: TextStyle(
                        color: ObsidianTheme.neonCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Zoom Controls HUD (Right Side)
          Positioned(
            top: 70,
            right: 14,
            child: Column(
              children: [
                _buildZoomButton(
                  icon: Icons.add,
                  onTap: () {
                    final z = _mapController.camera.zoom + 1.0;
                    _mapController.move(_mapController.camera.center, z);
                  },
                ),
                const SizedBox(height: 6),
                _buildZoomButton(
                  icon: Icons.remove,
                  onTap: () {
                    final z = _mapController.camera.zoom - 1.0;
                    _mapController.move(_mapController.camera.center, z);
                  },
                ),
              ],
            ),
          ),

          // 4. Selected Node Callout Card (Bottom)
          if (_selectedNode != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ObsidianTheme.surfaceGlass.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ObsidianTheme.neonCyan, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: ObsidianTheme.neonCyan.withOpacity(0.2), blurRadius: 16),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedNode!.name,
                            style: const TextStyle(
                              color: ObsidianTheme.neonCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: ObsidianTheme.textMuted, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _selectedNode = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedNode!.registeredAddress ?? "Indirizzo non disponibile nei registri",
                      style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Coordinate: Lat ${_selectedNode!.latitude!.toStringAsFixed(4)}, Lon ${_selectedNode!.longitude!.toStringAsFixed(4)} (Geocodificato via Nominatim)",
                      style: const TextStyle(color: ObsidianTheme.textDim, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text("APRI DOSSIER AZIENDALE & BILANCI"),
                        onPressed: () {
                          CompanyDossierSheet.show(context, _selectedNode!.id);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Collapsible Bottom List of Headquarters
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ObsidianTheme.surfaceGlass.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ObsidianTheme.borderGlow),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isListExpanded = !_isListExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.list_alt, color: ObsidianTheme.neonCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Elenco Sedi Rilevate (${geoNodes.length})",
                                style: const TextStyle(
                                  color: ObsidianTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isListExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: ObsidianTheme.neonCyan,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    if (_isListExpanded) ...[
                      const Divider(color: ObsidianTheme.borderSubtle),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: geoNodes.length,
                          separatorBuilder: (_, __) => const Divider(color: ObsidianTheme.borderSubtle, height: 1),
                          itemBuilder: (ctx, idx) {
                            final node = geoNodes[idx];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.location_on, color: ObsidianTheme.neonCyan, size: 18),
                              title: Text(node.name, style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 12)),
                              subtitle: Text(node.registeredAddress ?? '', style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 10)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 10, color: ObsidianTheme.textDim),
                              onTap: () {
                                final latLng = LatLng(node.latitude!, node.longitude!);
                                setState(() {
                                  _selectedNode = node;
                                  _isListExpanded = false;
                                });
                                _mapController.move(latLng, 12.0);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: ObsidianTheme.surfaceGlass.withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ObsidianTheme.borderGlow),
          ),
          child: Icon(icon, color: ObsidianTheme.neonCyan, size: 18),
        ),
      ),
    );
  }
}
