import 'package:flutter/material.dart';
import '../core/theme.dart';

class LiveRefreshDialog extends StatelessWidget {
  final String entityName;
  final VoidCallback onConfirm;

  const LiveRefreshDialog({
    super.key,
    required this.entityName,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, String entityName, VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (ctx) => LiveRefreshDialog(entityName: entityName, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ObsidianTheme.surfaceGlass,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ObsidianTheme.borderGlow),
      ),
      title: const Row(
        children: [
          Icon(Icons.sync_problem, color: ObsidianTheme.neonAmber, size: 24),
          SizedBox(width: 10),
          Text(
            "Conferma Aggiornamento Live",
            style: TextStyle(color: ObsidianTheme.textPrimary, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Stai per richiedere l'aggiornamento in tempo reale dei registri per:",
            style: const TextStyle(color: ObsidianTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            entityName,
            style: const TextStyle(
              color: ObsidianTheme.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ObsidianTheme.obsidianBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ObsidianTheme.neonAmber.withOpacity(0.5)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: ObsidianTheme.neonAmber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Attenzione: questa operazione consumerà 1 chiamata API dalla tua quota personale (BYOK). Lo stato precedente verrà archiviato nella cronologia storica.",
                    style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla", style: TextStyle(color: ObsidianTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ObsidianTheme.neonCyan,
            foregroundColor: ObsidianTheme.obsidianBackground,
          ),
          child: const Text("Conferma ed Esegui"),
        ),
      ],
    );
  }
}
