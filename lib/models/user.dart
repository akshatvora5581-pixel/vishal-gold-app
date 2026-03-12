import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? userType; // 'retailer' or 'wholesaler'
  final String? companyName;
  final String? companyAddress;
  final String? city;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.userType,
    this.companyName,
    this.companyAddress,
    this.city,
    this.profileImageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return User(
      id: json['id'] as String? ?? '',
      fullName: (json['fullName'] ?? json['full_name']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      userType: (json['userType'] ?? json['user_type']) as String?,
      companyName: (json['companyName'] ?? json['company_name']) as String?,
      companyAddress: (json['companyAddress'] ?? json['company_address']) as String?,
      city: json['city'] as String?,
      profileImageUrl: (json['profileImageUrl'] ?? json['profile_image_url']) as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'userType': userType,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'city': city,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? userType,
    String? companyName,
    String? companyAddress,
    String? city,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      city: city ?? this.city,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isWholesaler => userType == 'wholesaler';
  bool get isRetailer => userType == 'retailer';
}
