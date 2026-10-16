import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'auth_provider.dart';

/// Store profile state provider.
class StoreProvider extends ChangeNotifier {
  Map<String, dynamic>? _store;
  bool _isLoading = false;
  AuthProvider? _auth;
  String _language = 'hi';
  bool _notificationsEnabled = false;
  String _storeName = '';
  String _city = '';
  String _category = 'general';
  String? _trackingMethod;

  Map<String, dynamic>? get store => _store;
  bool get isLoading => _isLoading;
  String? get storeId => _auth?.storeId;
  String get onboardingLanguage => _language;
  bool get onboardingNotificationsEnabled => _notificationsEnabled;
  String get onboardingStoreName => _storeName;
  String get onboardingCity => _city;
  String get onboardingCategory => _category;
  String? get onboardingTrackingMethod => _trackingMethod;

  void setOnboardingLanguage(String value) => _language = value;
  void setOnboardingNotifications(bool value) => _notificationsEnabled = value;
  void setOnboardingStoreBasics({
    required String name,
    required String city,
    required String category,
  }) {
    _storeName = name;
    _city = city;
    _category = category;
  }

  void setOnboardingTrackingMethod(String value) => _trackingMethod = value;

  Future<bool> submitOnboarding() {
    if (_storeName.isEmpty || _city.isEmpty || _trackingMethod == null) {
      return Future.value(false);
    }
    return completeOnboarding({
      'store_name': _storeName,
      'category': _category,
      'city': _city,
      'language_pref': _language,
      'tracking_method': _trackingMethod,
      'notification_enabled': _notificationsEnabled,
    });
  }

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  Future<void> loadStore() async {
    if (_auth?.storeId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _store = await ApiClient.getStore(_auth!.storeId!);
    } catch (e) {
      debugPrint('Failed to load store: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> completeOnboarding(Map<String, dynamic> data) async {
    if (_auth?.storeId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      _store = await ApiClient.completeOnboarding(_auth!.storeId!, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    if (_auth?.storeId == null) return;
    try {
      _store = await ApiClient.updateStore(_auth!.storeId!, data);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update store: $e');
    }
  }
}
