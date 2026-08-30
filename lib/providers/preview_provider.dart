import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';

class PreviewProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isPreviewMode = false;
  int _pendingChangesCount = 0;

  bool get isPreviewMode => _isPreviewMode;
  int get pendingChangesCount => _pendingChangesCount;

  PreviewProvider() {
    _initStagingListener();
  }

  void _initStagingListener() {
    _firebaseService.getStagingChanges().listen((snapshot) {
      _pendingChangesCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  void togglePreviewMode() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

  void setPreviewMode(bool value) {
    _isPreviewMode = value;
    notifyListeners();
  }

  /// Helper to merge live data with staged changes for a specific collection
  /// This is simplified; in a production app, you might want to handle complex merging.
  List<T> mergeWithStaging<T>(
    List<T> liveItems,
    List<QueryDocumentSnapshot> stagedDocs,
    T Function(Map<String, dynamic> data, String id) fromJson,
    String Function(T item) getId, {
    bool force = false,
  }) {
    if (!_isPreviewMode && !force) return liveItems;

    final Map<String, T> mergedMap = {
      for (var item in liveItems) getId(item): item,
    };

    for (var doc in stagedDocs) {
      final change = doc.data() as Map<String, dynamic>;
      final String changeType = change['change_type'];
      final String docId = change['doc_id'];
      final Map<String, dynamic>? data = change['data'];

      if (changeType == 'delete') {
        mergedMap.remove(docId);
      } else if (data != null) {
        mergedMap[docId] = fromJson(data, docId);
      }
    }

    return mergedMap.values.toList();
  }
}
