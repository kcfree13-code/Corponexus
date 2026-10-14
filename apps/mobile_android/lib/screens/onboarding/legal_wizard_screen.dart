import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/obsidian_card.dart';
import '../home/home_dashboard_screen.dart';

class LegalWizardScreen extends ConsumerStatefulWidget {
  const LegalWizardScreen({super.key});

  @override
  ConsumerState<LegalWizardScreen> createState() => _LegalWizardScreenState();
}

class _LegalWizardScreenState extends ConsumerState<LegalWizardScreen> {
  int _currentStep = 0;

  // Step 1: Mandatory Italian Legal Clauses Checkboxes
  bool _clause1Accepted = false;
  bool _clause2Accepted = false;
  bool _clause3Accepted = false;
  bool _isSubmittingConsent = false;

  // Step 3: API Key Controller
  final TextEditingController _apiKeyController = TextEditingController();

  bool get _canProceedStep1 =>
      _clause1Accepted && _clause2Accepted && _clause3Accepted && !_isSubmittingConsent;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
    );
  }

  void _showServerSettings(BuildContext context) async {
    final storage = ref.read(secureStorageProvider);
    final currentUrl = await storage.getBackendUrl() ?? AppConstants.defaultBackendUrl;
    final controller = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ObsidianTheme.surfaceCard,
        title: const Text("Configurazione Server", style: TextStyle(color: ObsidianTheme.neonCyan, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "URL Backend CorpNexus (FastAPI):",
              style: TextStyle(color: ObsidianTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: ObsidianTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                filled: true,
                fillColor: ObsidianTheme.surfaceGlass,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud_outlined, color: ObsidianTheme.neonCyan),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              controller.text = AppConstants.defaultBackendUrl;
              await storage.saveBackendUrl(AppConstants.defaultBackendUrl);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Ripristina Default", style: TextStyle(color: ObsidianTheme.neonAmber)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await storage.saveBackendUrl(newUrl);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("CORPNEXUS ONBOARDING"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: ObsidianTheme.neonCyan),
            tooltip: "Configurazione Server",
            onPressed: () => _showServerSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _buildStepIndicator(0, "1. Termini Legali"),
                  const Expanded(child: Divider(color: ObsidianTheme.borderSubtle)),
                  _buildStepIndicator(1, "2. Guida Chiavi"),
                  const Expanded(child: Divider(color: ObsidianTheme.borderSubtle)),
                  _buildStepIndicator(2, "3. Configurazione"),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1LegalClauses(),
                  _buildStep2GuidedAcquisition(),
                  _buildStep3KeySetup(authState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone
              ? ObsidianTheme.neonGreen
              : (isActive ? ObsidianTheme.neonCyan : ObsidianTheme.surfaceGlassHigh),
          child: Text(
            "${stepIndex + 1}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (isActive || isDone)
                  ? ObsidianTheme.obsidianBackground
                  : ObsidianTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? ObsidianTheme.neonCyan : ObsidianTheme.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // --- STEP 1: Mandatory Italian Legal Text ---
  Widget _buildStep1LegalClauses() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Consenso Operativo e Clausole di Integrità",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ObsidianTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Per accedere all'intelligence societaria con politica Zero-Deduzioni, prendi visione ed accetta le tre clausole obbligatorie:",
            style: TextStyle(fontSize: 13, color: ObsidianTheme.textMuted),
          ),
          const SizedBox(height: 16),

          // Card 1
          ObsidianCard(
            borderColor: _clause1Accepted ? ObsidianTheme.neonCyan : ObsidianTheme.borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.legalTitle1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ObsidianTheme.neonCyan,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.legalBody1,
                  style: TextStyle(fontSize: 12, color: ObsidianTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: ObsidianTheme.neonCyan,
                  checkColor: ObsidianTheme.obsidianBackground,
                  value: _clause1Accepted,
                  title: const Text(
                    AppConstants.legalCheckbox1,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ObsidianTheme.textPrimary),
                  ),
                  onChanged: (val) => setState(() => _clause1Accepted = val ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 2
          ObsidianCard(
            borderColor: _clause2Accepted ? ObsidianTheme.neonCyan : ObsidianTheme.borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.legalTitle2,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ObsidianTheme.neonCyan,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.legalBody2,
                  style: TextStyle(fontSize: 12, color: ObsidianTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: ObsidianTheme.neonCyan,
                  checkColor: ObsidianTheme.obsidianBackground,
                  value: _clause2Accepted,
                  title: const Text(
                    AppConstants.legalCheckbox2,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ObsidianTheme.textPrimary),
                  ),
                  onChanged: (val) => setState(() => _clause2Accepted = val ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 3
          ObsidianCard(
            borderColor: _clause3Accepted ? ObsidianTheme.neonCyan : ObsidianTheme.borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.legalTitle3,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ObsidianTheme.neonCyan,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.legalBody3,
                  style: TextStyle(fontSize: 12, color: ObsidianTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: ObsidianTheme.neonCyan,
                  checkColor: ObsidianTheme.obsidianBackground,
                  value: _clause3Accepted,
                  title: const Text(
                    AppConstants.legalCheckbox3,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ObsidianTheme.textPrimary),
                  ),
                  onChanged: (val) => setState(() => _clause3Accepted = val ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Prosegui Button (strictly disabled until all 3 are checked and API accepted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProceedStep1
                  ? () async {
                      setState(() => _isSubmittingConsent = true);
                      final success = await ref.read(authProvider.notifier).submitConsent(
                            clause1: _clause1Accepted,
                            clause2: _clause2Accepted,
                            clause3: _clause3Accepted,
                          );
                      setState(() => _isSubmittingConsent = false);
                      if (success) {
                        setState(() => _currentStep = 1);
                      } else {
                        final errorDetail = ref.read(authProvider).verificationError;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorDetail != null
                                  ? "Errore registrazione consenso: $errorDetail"
                                  : "Errore durante la registrazione del consenso sul server.",
                            ),
                            backgroundColor: ObsidianTheme.alertRed,
                          ),
                        );
                      }
                    }
                  : null,
              child: _isSubmittingConsent
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTheme.obsidianBackground),
                    )
                  : const Text("PROSEGUI AL PASSO 2"),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: Guided Key Acquisition ---
  Widget _buildStep2GuidedAcquisition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Guida all'Acquisizione Token (BYOK)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ObsidianTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "CorpNexus adotta il modello BYOK (Bring Your Own Key). Puoi ottenere gratuitamente una API Key personale dai registri ufficiali:",
            style: TextStyle(fontSize: 13, color: ObsidianTheme.textMuted),
          ),
          const SizedBox(height: 20),
          ObsidianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, color: ObsidianTheme.neonCyan),
                    SizedBox(width: 8),
                    Text(
                      "OpenCorporates API Key",
                      style: TextStyle(fontWeight: FontWeight.bold, color: ObsidianTheme.neonCyan, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "1. Registrati gratuitamente al portale sviluppatori OpenCorporates.\n"
                  "2. Conferma la tua email e accedi alla dashboard utente.\n"
                  "3. Copia il tuo token API personale (api_token).",
                  style: TextStyle(fontSize: 13, color: ObsidianTheme.textMuted, height: 1.5),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text("Apri Portale OpenCorporates"),
                  onPressed: () async {
                    final uri = Uri.parse(AppConstants.openCorporatesRegisterUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text("INDIETRO"),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text("CONFIGURA CHIAVE"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 3: Setup & Verification ---
  Widget _buildStep3KeySetup(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verifica e Salvataggio Sicuro",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ObsidianTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Inserisci la tua API Key. Verrà cifrata localmente in flutter_secure_storage e utilizzata solo per le tue interrogazioni live.",
            style: TextStyle(fontSize: 13, color: ObsidianTheme.textMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(color: ObsidianTheme.textPrimary),
            decoration: InputDecoration(
              labelText: "OpenCorporates API Key",
              labelStyle: const TextStyle(color: ObsidianTheme.textMuted),
              filled: true,
              fillColor: ObsidianTheme.surfaceGlass,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ObsidianTheme.neonCyan),
              ),
              prefixIcon: const Icon(Icons.key, color: ObsidianTheme.neonCyan),
            ),
          ),
          if (authState.verificationError != null) ...[
            const SizedBox(height: 10),
            Text(
              authState.verificationError!,
              style: const TextStyle(color: ObsidianTheme.alertRed, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authState.isVerifying
                  ? null
                  : () async {
                      final key = _apiKeyController.text.trim();
                      if (key.isEmpty) return;
                      final ok = await ref.read(authProvider.notifier).verifyAndSaveByok(key);
                      if (ok) {
                        _goToHome();
                      }
                    },
              child: authState.isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTheme.obsidianBackground),
                    )
                  : const Text("VERIFICA E SALVA"),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).continueReadOnly();
                _goToHome();
              },
              child: const Text(
                "Continua in Sola Lettura (Solo Database Condiviso)",
                style: TextStyle(
                  color: ObsidianTheme.neonAmber,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
