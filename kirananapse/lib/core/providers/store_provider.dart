import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'auth_provider.dart';

/// Store profile state provider.
class StoreProvider extends ChangeNotifier {
  Map<String, dynamic>? _store;
  bool _isLoading = false;
  AuthProvider? _auth;

  Map<String, dynamic>? get store => _store;
  bool get isLoading => _isLoading;
  String? get storeId => _auth?.storeId;

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
