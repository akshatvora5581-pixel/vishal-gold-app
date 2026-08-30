import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';

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
          final dynamic dateData = data['createdAt'];
          DateTime? date;
          if (dateData is Timestamp) {
            date = dateData.toDate();
          } else if (dateData is String) {
            date = DateTime.tryParse(dateData);
          }

          if (date != null) {
            final monthKey = _getMonthKey(date);
            if (trends.containsKey(monthKey)) {
              trends[monthKey] = trends[monthKey]! + 1;
            }
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

  // --- NEW FEATURES FOR ADMIN HUB ---

  // Collection names
  static const String presenceCollection = 'presence';
  static const String analyticsCacheCollection = 'analytics_cache';

  /// 1. REAL-TIME TRAFFIC TRACKING

  /// Track user presence when they open the app
  Future<void> updatePresence(String userId, String role) async {
    try {
      await _firestore.collection(presenceCollection).doc(userId).set({
        'lastActive': FieldValue.serverTimestamp(),
        'role': role,
        'status': 'online',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Get stream of active users (active in last 5 minutes)
  Stream<int> getActiveUserCount() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _firestore
        .collection(presenceCollection)
        .where('lastActive', isGreaterThan: fiveMinutesAgo)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 2. SALES & CATEGORY PERFORMANCE (BI)

  /// Aggregates sales by category for heatmaps
  Future<Map<String, double>> getSalesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseService.ordersCollection);

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }
      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      final snapshot = await query.get();
      final Map<String, double> performance = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List items = data['items'] ?? [];

        for (var item in items) {
          final String category =
              item['categoryDisplay'] ?? item['category'] ?? 'Others';
          final double weight = (item['netWeight'] as num?)?.toDouble() ?? 0.0;
          final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;

          performance[category] =
              (performance[category] ?? 0.0) + (weight * quantity);
        }
      }

      return performance;
    } catch (e) {
      debugPrint('Error fetching sales by category: $e');
      return {};
    }
  }

  /// 3. CUSTOMER INSIGHTS

  /// Identifies top customers based on spend
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseService.usersCollection)
          .get();
      List<Map<String, dynamic>> customers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final double totalSpend =
            (data['totalOrderValue'] as num?)?.toDouble() ?? 0.0;
        final int orderCount = (data['orderCount'] as num?)?.toInt() ?? 0;

        if (orderCount > 0) {
          customers.add({
            'uid': doc.id,
            'name': data['fullName'] ?? data['name'] ?? 'Unknown',
            'email': data['email'] ?? '',
            'totalSpend': totalSpend,
            'orderCount': orderCount,
            'role': data['role'] ?? 'retailer',
          });
        }
      }

      // Sort by spend
      customers.sort((a, b) => b['totalSpend'].compareTo(a['totalSpend']));

      return customers.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching top customers: $e');
      return [];
    }
  }

  /// 4. PREDICTIVE INVENTORY

  /// Suggests stock levels based on last 90 days trend
  Future<List<Map<String, dynamic>>> getInventoryPredictions() async {
    try {
      // Small optimization: Use last 90 days for trend
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final sales = await getSalesByCategory(startDate: ninetyDaysAgo);

      List<Map<String, dynamic>> predictions = [];
      sales.forEach((category, totalWeight) {
        final dailyAvg = totalWeight / 90;
        predictions.add({
          'category': category,
          'dailyAvg': dailyAvg,
          'suggestedStock': dailyAvg * 15, // Suggested 15 days buffer
          'trend': 'Stable',
        });
      });

      return predictions;
    } catch (e) {
      debugPrint('Error calculating inventory predictions: $e');
      return [];
    }
  }

  // --- CRM & Segmentation ---

  Future<List<Map<String, dynamic>>> getInactiveUsers(int days) async {
    final threshold = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _firestore
        .collection('users')
        .where('lastLogin', isLessThan: threshold)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  FirebaseFirestore get firestore => _firestore;
}
