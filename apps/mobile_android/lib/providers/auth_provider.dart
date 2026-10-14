import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storageService: storage);
});

class AuthState {
  final bool isConsentAccepted;
  final String? byokToken;
  final bool isVerifying;
  final String? verificationError;

  AuthState({
    required this.isConsentAccepted,
    this.byokToken,
    this.isVerifying = false,
    this.verificationError,
  });

  AuthState copyWith({
    bool? isConsentAccepted,
    String? byokToken,
    bool? isVerifying,
    String? verificationError,
  }) {
    return AuthState(
      isConsentAccepted: isConsentAccepted ?? this.isConsentAccepted,
      byokToken: byokToken ?? this.byokToken,
      isVerifying: isVerifying ?? this.isVerifying,
      verificationError: verificationError,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final ApiClient _api;

  AuthNotifier(this._storage, this._api)
      : super(AuthState(isConsentAccepted: false)) {
    _init();
  }

  Future<void> _init() async {
    final accepted = await _storage.isConsentAccepted();
    final token = await _storage.getByokToken();
    state = state.copyWith(isConsentAccepted: accepted, byokToken: token);
  }

  Future<bool> submitConsent({
    required bool clause1,
    required bool clause2,
    required bool clause3,
  }) async {
    try {
      await _api.registerConsent(
        clause1: clause1,
        clause2: clause2,
        clause3: clause3,
      );
      await _storage.saveConsentAccepted(true);
      state = state.copyWith(isConsentAccepted: true);
      return true;
    } catch (e) {
      state = state.copyWith(verificationError: e.toString());
      return false;
    }
  }

  Future<bool> verifyAndSaveByok(String key) async {
    state = state.copyWith(isVerifying: true, verificationError: null);
    try {
      final res = await _api.verifyApiKey(provider: "opencorporates", apiKey: key);
      final isValid = res["is_valid"] == true;
      if (isValid) {
        await _storage.saveByokToken(key);
        state = state.copyWith(byokToken: key, isVerifying: false);
        return true;
      } else {
        state = state.copyWith(
          isVerifying: false,
          verificationError: res["message"] ?? "Chiave API non valida",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        verificationError: "Errore durante la verifica della chiave: $e",
      );
      return false;
    }
  }

  Future<void> continueReadOnly() async {
    await _storage.saveByokToken("");
    state = state.copyWith(byokToken: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(storage, api);
});
