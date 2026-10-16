import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Available backend environments
enum ApiEnvironment {
  local,        // Local Dev: 10.0.2.2 for Android emulator or localhost for Web/Desktop
  deployed,     // Render Cloud: https://kirana-napse-backend.onrender.com/api/v1
  custom,       // Custom IP for WiFi testing with physical devices
}

/// Dynamic application configuration and environment manager.
class AppConfig {
  static const String _prefEnvKey = 'selected_api_env';
  static const String _prefCustomUrlKey = 'custom_api_url';
  static const String _prefAutoFallbackKey = 'auto_fallback_enabled';

  // Preset Endpoints
  static const String deployedUrl = 'https://kirana-napse-backend.onrender.com/api/v1';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000/api/v1';
  static const String localhostUrl = 'http://localhost:8000/api/v1';

  static ApiEnvironment _currentEnv = ApiEnvironment.local;
  static String _customUrl = '';
  static bool _autoFallback = true;

  static ApiEnvironment get currentEnv => _currentEnv;
  static String get customUrl => _customUrl;
  static bool get autoFallback => _autoFallback;

  /// Default local URL based on platform
  static String get defaultLocalUrl {
    if (kIsWeb) return localhostUrl;
    try {
      if (Platform.isAndroid) return androidEmulatorUrl;
    } catch (_) {}
    return localhostUrl;
  }

  /// Check if a given URL points to a local machine/emulator
  static bool isLocalUrl(String url) {
    return url.contains('10.0.2.2') ||
        url.contains('localhost') ||
        url.contains('127.0.0.1') ||
        url.startsWith('http://192.168.') ||
        url.startsWith('http://10.') ||
        url.startsWith('http://172.');
  }

  /// Get current effective base URL (Defaults to Local for testing)
  static String get baseUrl {
    switch (_currentEnv) {
      case ApiEnvironment.deployed:
        return deployedUrl;
      case ApiEnvironment.custom:
        return _customUrl.isNotEmpty ? _customUrl : defaultLocalUrl;
      case ApiEnvironment.local:
        return defaultLocalUrl;
    }
  }

  /// Initialize config from SharedPreferences or build flags on app startup
  static Future<void> initialize() async {
    // Check if --dart-define=ENV=production or ENV=local was passed
    const compileEnv = String.fromEnvironment('ENV', defaultValue: '');
    if (compileEnv.toLowerCase() == 'production' || compileEnv.toLowerCase() == 'deployed') {
      _currentEnv = ApiEnvironment.deployed;
    } else if (compileEnv.toLowerCase() == 'local') {
      _currentEnv = ApiEnvironment.local;
    } else {
      // Load saved user preference or default to local
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedEnvIndex = prefs.getInt(_prefEnvKey);
        _customUrl = prefs.getString(_prefCustomUrlKey) ?? '';
        _autoFallback = prefs.getBool(_prefAutoFallbackKey) ?? true;

        if (savedEnvIndex != null &&
            savedEnvIndex >= 0 &&
            savedEnvIndex < ApiEnvironment.values.length) {
          _currentEnv = ApiEnvironment.values[savedEnvIndex];
        } else {
          // Default to Local for testing
          _currentEnv = ApiEnvironment.local;
        }
      } catch (_) {
        _currentEnv = ApiEnvironment.local;
        _autoFallback = true;
      }
    }

    ApiClient.updateBaseUrl(baseUrl);
  }

  /// Switch environment and persist selection
  static Future<void> setEnvironment(ApiEnvironment env, {String? customUrl}) async {
    _currentEnv = env;
    if (customUrl != null) {
      _customUrl = customUrl;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefEnvKey, env.index);
    if (customUrl != null) {
      await prefs.setString(_prefCustomUrlKey, _customUrl);
    }

    ApiClient.updateBaseUrl(baseUrl);
  }

  /// Toggle automatic fallback to deployed Render server
  static Future<void> setAutoFallback(bool value) async {
    _autoFallback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoFallbackKey, value);
  }

  /// Formatted label for UI
  static String get environmentLabel {
    switch (_currentEnv) {
      case ApiEnvironment.local:
        return 'Local Testing (${baseUrl.replaceAll('/api/v1', '')})';
      case ApiEnvironment.deployed:
        return 'Render Cloud (Production)';
      case ApiEnvironment.custom:
        return 'Custom URL (${baseUrl.replaceAll('/api/v1', '')})';
    }
  }
}
