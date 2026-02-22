import 'package:cloud_firestore/cloud_firestore.dart';

class MarketSettings {
  final double goldRate24K;
  final double goldRate22K;
  final double goldRate18K;
  final DateTime updatedAt;

  MarketSettings({
    required this.goldRate24K,
    required this.goldRate22K,
    required this.goldRate18K,
    required this.updatedAt,
  });

  factory MarketSettings.fromJson(Map<String, dynamic> json) {
    return MarketSettings(
      goldRate24K: (json['gold_rate_24k'] ?? 0.0).toDouble(),
      goldRate22K: (json['gold_rate_22k'] ?? 0.0).toDouble(),
      goldRate18K: (json['gold_rate_18k'] ?? 0.0).toDouble(),
      updatedAt: json['updated_at'] is Timestamp
          ? (json['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gold_rate_24k': goldRate24K,
      'gold_rate_22k': goldRate22K,
      'gold_rate_18k': goldRate18K,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  MarketSettings copyWith({
    double? goldRate24K,
    double? goldRate22K,
    double? goldRate18K,
  }) {
    return MarketSettings(
      goldRate24K: goldRate24K ?? this.goldRate24K,
      goldRate22K: goldRate22K ?? this.goldRate22K,
      goldRate18K: goldRate18K ?? this.goldRate18K,
      updatedAt: DateTime.now(),
    );
  }
}
