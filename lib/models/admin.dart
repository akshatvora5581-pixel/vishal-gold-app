import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String id;
  final String fullName;
  final String email;
  final String? whatsappNumber;
  final String? secondaryEmail;
  final String role; // 'super', 'manager', 'editor'
  final Map<String, dynamic>? contactDetails;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Admin({
    required this.id,
    required this.fullName,
    required this.email,
    this.whatsappNumber,
    this.secondaryEmail,
    required this.role,
    this.contactDetails,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return Admin(
      id: id,
      fullName: json['full_name'] as String? ?? 'Unnamed Admin',
      email: json['email'] as String? ?? '',
      whatsappNumber: json['whatsapp_number'] as String?,
      secondaryEmail: json['secondary_email'] as String?,
      role: json['role'] as String? ?? 'editor',
      contactDetails: json['contact_details'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'whatsapp_number': whatsappNumber,
      'secondary_email': secondaryEmail,
      'role': role,
      'contact_details': contactDetails,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Admin copyWith({
    String? fullName,
    String? email,
    String? whatsappNumber,
    String? secondaryEmail,
    String? role,
    Map<String, dynamic>? contactDetails,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Admin(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      secondaryEmail: secondaryEmail ?? this.secondaryEmail,
      role: role ?? this.role,
      contactDetails: contactDetails ?? this.contactDetails,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSuperAdmin => role == 'super';
  bool get canManageInventory => role == 'super' || role == 'manager';
}
