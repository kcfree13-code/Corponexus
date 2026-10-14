import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/legal_wizard_screen.dart';
import 'screens/home/home_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: CorpNexusApp(),
    ),
  );
}

class CorpNexusApp extends ConsumerWidget {
  const CorpNexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'CorpNexus Android',
      debugShowCheckedModeBanner: false,
      theme: ObsidianTheme.darkTheme,
      home: authState.isConsentAccepted
          ? const HomeDashboardScreen()
          : const LegalWizardScreen(),
    );
  }
}
