import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyConsentAccepted = "legal_consent_accepted";
  static const String _keyByokToken = "opencorporates_api_key";
  static const String _keyInseeToken = "insee_sirene_token";
  static const String _keyBackendUrl = "custom_backend_url";

  Future<void> saveConsentAccepted(bool accepted) async {
    await _storage.write(key: _keyConsentAccepted, value: accepted ? "true" : "false");
  }

  Future<bool> isConsentAccepted() async {
    final val = await _storage.read(key: _keyConsentAccepted);
    return val == "true";
  }

  Future<void> saveByokToken(String token) async {
    await _storage.write(key: _keyByokToken, value: token);
  }

  Future<String?> getByokToken() async {
    return await _storage.read(key: _keyByokToken);
  }

  Future<void> saveInseeToken(String token) async {
    await _storage.write(key: _keyInseeToken, value: token);
  }

  Future<String?> getInseeToken() async {
    return await _storage.read(key: _keyInseeToken);
  }

  Future<void> saveBackendUrl(String url) async {
    await _storage.write(key: _keyBackendUrl, value: url);
  }

  Future<String?> getBackendUrl() async {
    return await _storage.read(key: _keyBackendUrl);
  }
}
