import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'auth_provider.dart';

/// Recommendation state provider for daily recommendations.
class RecommendationProvider extends ChangeNotifier {
  Map<String, dynamic>? _todayData;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _auth;

  Map<String, dynamic>? get todayData => _todayData;
  List<Map<String, dynamic>> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get reorderCount => _todayData?['reorder_count'] ?? 0;
  int get overstockCount => _todayData?['overstock_count'] ?? 0;
  int get expiryRiskCount => _todayData?['expiry_risk_count'] ?? 0;
  int get lowStockCount => _todayData?['low_stock_count'] ?? 0;

  List<Map<String, dynamic>> get reorderItems => _recommendations
      .where((r) => r['type'] == 'reorder' || r['type'] == 'low_stock')
      .toList();

  List<Map<String, dynamic>> get overstockItems => _recommendations
      .where((r) => r['type'] == 'overstock' || r['type'] == 'expiry_risk')
      .toList();

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  Future<void> loadRecommendations() async {
    if (_auth?.storeId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayData = await ApiClient.getTodayRecommendations(_auth!.storeId!);
      _recommendations = List<Map<String, dynamic>>.from(
        _todayData?['recommendations'] ?? [],
      );
    } catch (e) {
      debugPrint('Failed to load recommendations: $e');
      _error = 'Could not load recommendations. Pull down to try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateRecommendation(
    String recId,
    String status, {
    double? editedQty,
  }) async {
    try {
      final Map<String, dynamic> body = {'status': status};
      if (editedQty != null) body['owner_edited_qty'] = editedQty;
      await ApiClient.updateRecommendation(recId, body);
      // Update local state
      final idx = _recommendations.indexWhere((r) => r['id'] == recId);
      if (idx != -1) {
        _recommendations[idx]['status'] = status;
        if (editedQty != null) {
          _recommendations[idx]['owner_edited_qty'] = editedQty;
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to update recommendation: $e');
      return false;
    }
  }
}
