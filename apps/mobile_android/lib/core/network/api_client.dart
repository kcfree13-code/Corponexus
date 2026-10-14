import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storageService;

  ApiClient({required this.storageService, String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.defaultBackendUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      ),
    );

    // Interceptor to inject BYOK API Key if available
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getByokToken();
          if (token != null && token.isNotEmpty) {
            options.headers["X-API-Key"] = token;
          }
          return handler.next(options);
        },
      ),
    );
  }

  // --- Auth & Consent ---

  Future<Map<String, dynamic>> registerConsent({
    required bool clause1,
    required bool clause2,
    required bool clause3,
  }) async {
    final response = await dio.post(
      "/api/v1/auth/consent",
      data: {
        "clause_1_byok_accepted": clause1,
        "clause_2_shared_cache_accepted": clause2,
        "clause_3_zero_inference_disclaimer_accepted": clause3,
        "terms_version": AppConstants.termsVersion,
        "app_platform": "Android Flutter",
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyApiKey({
    required String provider,
    required String apiKey,
  }) async {
    final response = await dio.post(
      "/api/v1/auth/verify-key",
      data: {
        "provider": provider,
        "api_key": apiKey,
      },
    );
    return response.data;
  }

  // --- Graph Exploration ---

  Future<Map<String, dynamic>> getEntityGraph(String entityId, {int degrees = 1}) async {
    final response = await dio.get(
      "/api/v1/graph/entity/$entityId",
      queryParameters: {"degrees": degrees},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> refreshEntityLive(String entityId) async {
    final response = await dio.post("/api/v1/graph/refresh/$entityId");
    return response.data;
  }

  Future<Map<String, dynamic>> getShortestPath({
    required String source,
    required String target,
    int maxDegrees = 6,
  }) async {
    final response = await dio.get(
      "/api/v1/graph/shortest-path",
      queryParameters: {
        "source": source,
        "target": target,
        "max_degrees": maxDegrees,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getHistoricalGraph({
    required String entityId,
    required String date,
  }) async {
    final response = await dio.get(
      "/api/v1/graph/historical",
      queryParameters: {
        "entity_id": entityId,
        "date": date,
      },
    );
    return response.data;
  }

  // --- Company Dossier ---

  Future<Map<String, dynamic>> getCompanyDossier(String companyId) async {
    final response = await dio.get("/api/v1/company/$companyId/dossier");
    return response.data;
  }

  // --- Search ---

  Future<Map<String, dynamic>> search(String query, {String? jurisdiction}) async {
    final response = await dio.get(
      "/api/v1/search",
      queryParameters: {
        "q": query,
        if (jurisdiction != null) "jurisdiction": jurisdiction,
      },
    );
    return response.data;
  }
}
