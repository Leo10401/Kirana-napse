import 'package:dio/dio.dart';
import 'app_config.dart';

/// API client for communicating with the Kirana-Napse backend.
class ApiClient {
  static String? _token;
  static String? _storeId;

  static String get baseUrl => AppConfig.baseUrl;

  static void setToken(String token) => _token = token;
  static void setStoreId(String storeId) => _storeId = storeId;
  static String? get storeId => _storeId;
  static String? get token => _token;
  static void clearAuth() {
    _token = null;
    _storeId = null;
  }

  /// Create a fresh Dio instance with clean base configuration
  static Dio _createDio(
    String baseUrl, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final dio = Dio(
      BaseOptions(
        baseUrl: cleanBase,
        connectTimeout: timeout,
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ),
    );
    return dio;
  }

  /// Check if an error was caused by connection failure (offline / timeout / connection refused)
  static bool _isConnectionError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          (error.response?.statusCode != null &&
              error.response!.statusCode! >= 502);
    }
    return false;
  }

  /// Core request executor with automatic, seamless fallback to Render Cloud
  static Future<Response<T>> _send<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final primaryUrl = AppConfig.baseUrl;
    final primaryDio = _createDio(
      primaryUrl,
      timeout: const Duration(seconds: 4),
    );

    try {
      return await primaryDio.request<T>(
        cleanPath,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 401) {
        _token = null;
        _storeId = null;
        rethrow;
      }

      // If primary is local and failed with connection error, and auto-fallback is enabled:
      if (AppConfig.autoFallback &&
          AppConfig.isLocalUrl(primaryUrl) &&
          _isConnectionError(error)) {
        // Fallback to deployed Render cloud (30s timeout for free-tier wake-up)
        final fallbackDio = _createDio(
          AppConfig.deployedUrl,
          timeout: const Duration(seconds: 30),
        );
        return await fallbackDio.request<T>(
          cleanPath,
          data: data,
          queryParameters: queryParameters,
          options: Options(method: method),
        );
      }
      rethrow;
    }
  }

  /// Dynamically update baseUrl (delegates to AppConfig)
  static void updateBaseUrl(String newUrl) {
    // Handled dynamically via AppConfig.baseUrl
  }

  /// Ping the /health endpoint of a target base URL
  static Future<Map<String, dynamic>> testHealthConnection([
    String? targetBaseUrl,
  ]) async {
    String effectiveUrl = targetBaseUrl ?? AppConfig.baseUrl;
    while (effectiveUrl.endsWith('/')) {
      effectiveUrl = effectiveUrl.substring(0, effectiveUrl.length - 1);
    }
    final healthEndpoint = effectiveUrl.endsWith('/api/v1')
        ? effectiveUrl.replaceAll('/api/v1', '/health')
        : '$effectiveUrl/health';

    final tempDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final response = await tempDio.get(healthEndpoint);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {'status': 'healthy', 'data': response.data};
  }

  // ─── Auth ───
  static Future<Map<String, dynamic>> register(
    String phone,
    String password,
    String? name,
  ) async {
    final Map<String, dynamic> body = {'phone': phone, 'password': password};
    if (name != null) body['name'] = name;
    final response = await _send<Map<String, dynamic>>(
      'POST',
      'auth/register',
      data: body,
    );
    return response.data!;
  }

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'POST',
      'auth/login',
      data: {'phone': phone, 'password': password},
    );
    return response.data!;
  }

  // ─── Store ───
  static Future<Map<String, dynamic>> completeOnboarding(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'POST',
      'stores/$storeId/onboarding',
      data: data,
    );
    return response.data!;
  }

  static Future<Map<String, dynamic>> getStore(String storeId) async {
    final response = await _send<Map<String, dynamic>>(
      'GET',
      'stores/$storeId',
    );
    return response.data!;
  }

  static Future<Map<String, dynamic>> updateStore(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'PATCH',
      'stores/$storeId',
      data: data,
    );
    return response.data!;
  }

  // ─── Recommendations ───
  static Future<Map<String, dynamic>> getTodayRecommendations(
    String storeId,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'GET',
      'stores/$storeId/recommendations/today',
    );
    return response.data!;
  }

  static Future<Map<String, dynamic>> updateRecommendation(
    String recId,
    Map<String, dynamic> data,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'PATCH',
      'recommendations/$recId',
      data: data,
    );
    return response.data!;
  }

  static Future<Map<String, dynamic>> flagRecommendation(
    String recId,
    Map<String, dynamic> data,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'POST',
      'recommendations/$recId/flag',
      data: data,
    );
    return response.data!;
  }

  // ─── Sales ───
  static Future<List<dynamic>> getItems(String storeId) async {
    final response = await _send<List<dynamic>>('GET', 'stores/$storeId/items');
    return response.data!;
  }

  static Future<Map<String, dynamic>> createItem(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'POST',
      'stores/$storeId/items',
      data: data,
    );
    return response.data!;
  }

  static Future<void> updateStock(
    String storeId,
    String skuId,
    double quantity,
  ) async {
    await _send<Map<String, dynamic>>(
      'POST',
      'stores/$storeId/stock',
      data: {'sku_id': skuId, 'quantity_on_hand': quantity},
    );
  }

  static Future<Map<String, dynamic>> addSalesEntry(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _send<Map<String, dynamic>>(
      'POST',
      'stores/$storeId/sales',
      data: data,
    );
    return response.data!;
  }

  static Future<List<dynamic>> getSalesHistory(
    String storeId, {
    String? skuId,
    int limit = 50,
  }) async {
    final Map<String, dynamic> query = {'limit': limit};
    if (skuId != null) query['sku_id'] = skuId;
    final response = await _send<List<dynamic>>(
      'GET',
      'stores/$storeId/sales',
      queryParameters: query,
    );
    return response.data!;
  }

  // ─── Export ───
  static Future<Map<String, dynamic>> getDistributorList(String storeId) async {
    final response = await _send<Map<String, dynamic>>(
      'GET',
      'stores/$storeId/export/distributor-list',
    );
    return response.data!;
  }

  // ─── Device ───
  static Future<void> registerDeviceToken(
    String storeId,
    String fcmToken, {
    String? deviceModel,
    String? osVersion,
  }) async {
    final Map<String, dynamic> body = {'fcm_token': fcmToken};
    if (deviceModel != null) body['device_model'] = deviceModel;
    if (osVersion != null) body['os_version'] = osVersion;
    await _send<void>('POST', 'stores/$storeId/device-tokens', data: body);
  }
}
