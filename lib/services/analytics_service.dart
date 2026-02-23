import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class AnalyticsService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String productsCollection = 'products';

  /// Fetches product upload trends for the last 6 months
  Future<Map<String, int>> getProductUploadTrends() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      final snapshot = await _firestore
          .collection(productsCollection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo),
          )
          .get();

      final Map<String, int> trends = {};

      // Initialize months
      for (int i = 0; i <= 6; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = _getMonthKey(date);
        trends[monthKey] = 0;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final date = (data['createdAt'] as Timestamp).toDate();
          final monthKey = _getMonthKey(date);
          if (trends.containsKey(monthKey)) {
            trends[monthKey] = trends[monthKey]! + 1;
          }
        }
      }

      return trends;
    } catch (e) {
      debugPrint('Error getting product upload trends: $e');
      return {};
    }
  }

  /// Fetches product count distribution per category
  Future<Map<String, int>> getCategoryDistribution() async {
    try {
      final snapshot = await _firestore.collection(productsCollection).get();
      final Map<String, int> distribution = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null) {
          distribution[category] = (distribution[category] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      debugPrint('Error getting category distribution: $e');
      return {};
    }
  }

  String _getMonthKey(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Fetches top trending products based on wishlist counts
  Future<List<Map<String, dynamic>>> getTrendingProducts({
    int limit = 5,
  }) async {
    return _firebaseService.getTrendingProducts(limit: limit);
  }
}
