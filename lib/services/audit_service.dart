import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAction({
    required String action,
    required String details,
    String? targetId,
    String? targetType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('audit_trail').add({
      'adminId': user.uid,
      'adminEmail': user.email,
      'action': action,
      'details': details,
      'targetId': targetId,
      'targetType': targetType,
      'timestamp': FieldValue.serverTimestamp(),
      'deviceInfo':
          'Mobile App', // Could be expanded with package:device_info_plus
    });
  }

  Stream<QuerySnapshot> getAuditLogs({int limit = 50}) {
    return _firestore
        .collection('audit_trail')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}
