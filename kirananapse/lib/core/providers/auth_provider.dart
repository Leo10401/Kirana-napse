import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

/// Authentication state provider.
class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _storeId;
  bool _isLoading = false;
  String? _error;
  bool _isOnboarded = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get storeId => _storeId;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnboarded => _isOnboarded;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _storeId = prefs.getString('store_id');
    _isOnboarded = prefs.getBool('is_onboarded') ?? false;
    if (_token != null) {
      ApiClient.setToken(_token!);
      if (_storeId != null) ApiClient.setStoreId(_storeId!);
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) prefs.setString('auth_token', _token!);
    if (_userId != null) prefs.setString('user_id', _userId!);
    if (_storeId != null) prefs.setString('store_id', _storeId!);
    prefs.setBool('is_onboarded', _isOnboarded);
  }

  Future<bool> register(String phone, String password, String? name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.register(phone, password, name);
      _token = data['access_token'];
      _userId = data['user_id'];
      _storeId = data['store_id'];
      ApiClient.setToken(_token!);
      if (_storeId != null) ApiClient.setStoreId(_storeId!);
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.login(phone, password);
      _token = data['access_token'];
      _userId = data['user_id'];
      _storeId = data['store_id'];
      ApiClient.setToken(_token!);
      if (_storeId != null) ApiClient.setStoreId(_storeId!);
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Invalid phone or password.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setOnboarded(bool value) {
    _isOnboarded = value;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _storeId = null;
    _isOnboarded = false;
    ApiClient.clearAuth();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
