class SampleOrder {
  final String? id;
  final String userId;
  final String group;
  final String itemName;
  final String qty;
  final String size;
  final String weight;
  final String total;
  final bool rodium;
  final bool huid;
  final List<String> imageUrls;
  final String? remarks;
  final String status;
  final DateTime? createdAt;

  SampleOrder({
    this.id,
    required this.userId,
    required this.group,
    required this.itemName,
    required this.qty,
    required this.size,
    required this.weight,
    required this.total,
    required this.rodium,
    required this.huid,
    required this.imageUrls,
    this.remarks,
    this.status = 'pending',
    this.createdAt,
  });

  factory SampleOrder.fromJson(Map<String, dynamic> json, {String? docId}) {
    return SampleOrder(
      id: docId ?? json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      group: json['group'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      qty: json['qty'] as String? ?? '',
      size: json['size'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      total: json['total'] as String? ?? '',
      rodium: json['rodium'] as bool? ?? false,
      huid: json['huid'] as bool? ?? false,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : [],
      remarks: json['remarks'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'] as String)
                : (json['createdAt'] as dynamic).toDate())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'group': group,
      'itemName': itemName,
      'qty': qty,
      'size': size,
      'weight': weight,
      'total': total,
      'rodium': rodium,
      'huid': huid,
      'imageUrls': imageUrls,
      'remarks': remarks,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
