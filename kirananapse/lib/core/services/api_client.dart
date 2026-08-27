import 'package:dio/dio.dart';

/// API client for communicating with the Kirana-Napse backend.
class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator → localhost
  static String? _token;
  static String? _storeId;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 — redirect to login
          if (error.response?.statusCode == 401) {
            _token = null;
            _storeId = null;
          }
          return handler.next(error);
        },
      ),
    );

  static void setToken(String token) => _token = token;
  static void setStoreId(String storeId) => _storeId = storeId;
  static String? get storeId => _storeId;
  static String? get token => _token;
  static void clearAuth() {
    _token = null;
    _storeId = null;
  }

  // ─── Auth ───
  static Future<Map<String, dynamic>> register(String phone, String password, String? name) async {
    final Map<String, dynamic> body = {
      'phone': phone,
      'password': password,
    };
    if (name != null) body['name'] = name;
    final response = await _dio.post('/auth/register', data: body);
    return response.data;
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return response.data;
  }

  // ─── Store ───
  static Future<Map<String, dynamic>> completeOnboarding(String storeId, Map<String, dynamic> data) async {
    final response = await _dio.post('/stores/$storeId/onboarding', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getStore(String storeId) async {
    final response = await _dio.get('/stores/$storeId');
    return response.data;
  }

  static Future<Map<String, dynamic>> updateStore(String storeId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/stores/$storeId', data: data);
    return response.data;
  }

  // ─── Recommendations ───
  static Future<Map<String, dynamic>> getTodayRecommendations(String storeId) async {
    final response = await _dio.get('/stores/$storeId/recommendations/today');
    return response.data;
  }

  static Future<Map<String, dynamic>> updateRecommendation(String recId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/recommendations/$recId', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> flagRecommendation(String recId, Map<String, dynamic> data) async {
    final response = await _dio.post('/recommendations/$recId/flag', data: data);
    return response.data;
  }

  // ─── Sales ───
  static Future<Map<String, dynamic>> addSalesEntry(String storeId, Map<String, dynamic> data) async {
    final response = await _dio.post('/stores/$storeId/sales', data: data);
    return response.data;
  }

  static Future<List<dynamic>> getSalesHistory(String storeId, {String? skuId, int limit = 50}) async {
    final Map<String, dynamic> query = {'limit': limit};
    if (skuId != null) query['sku_id'] = skuId;
    final response = await _dio.get('/stores/$storeId/sales', queryParameters: query);
    return response.data;
  }

  // ─── Export ───
  static Future<Map<String, dynamic>> getDistributorList(String storeId) async {
    final response = await _dio.get('/stores/$storeId/export/distributor-list');
    return response.data;
  }

  // ─── Device ───
  static Future<void> registerDeviceToken(String storeId, String fcmToken, {String? deviceModel, String? osVersion}) async {
    final Map<String, dynamic> body = {'fcm_token': fcmToken};
    if (deviceModel != null) body['device_model'] = deviceModel;
    if (osVersion != null) body['os_version'] = osVersion;
    await _dio.post('/stores/$storeId/device-tokens', data: body);
  }
}

