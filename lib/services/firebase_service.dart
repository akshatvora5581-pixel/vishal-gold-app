import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/order.dart' as app_order;
import 'package:vishal_gold/models/market_settings.dart';
import 'package:vishal_gold/models/app_banner.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String cartItemsCollection = 'cart_items';
  static const String wishlistItemsCollection = 'wishlist_items';
  static const String wholesalerUploadsCollection = 'wholesaler_uploads';
  static const String notificationsCollection = 'notifications';
  static const String recentViewsCollection = 'recent_views';
  static const String sampleOrdersCollection = 'sample_orders';
  static const String adminsCollection = 'admins';
  static const String categoriesCollection = 'categories';
  static const String subcategoriesCollection = 'subcategories';
  static const String auditLogsCollection = 'admin_logs';
  static const String marketSettingsCollection = 'market_settings';
  static const String bannersCollection = 'banners';
  static const String stagingCollection = 'staging';

  /// ========== STAGING OPERATIONS ==========

  /// Stage a change for later publishing
  Future<void> stageChange({
    required String adminId,
    required String collectionName,
    required String docId,
    Map<String, dynamic>? data,
    required String changeType, // 'create', 'update', 'delete'
  }) async {
    try {
      await _firestore.collection(stagingCollection).add({
        'timestamp': FieldValue.serverTimestamp(),
        'admin_id': adminId,
        'collection_name': collectionName,
        'doc_id': docId,
        'data': data,
        'change_type': changeType,
      });
    } catch (e) {
      throw 'Failed to stage change: ${e.toString()}';
    }
  }

  /// Get all staged changes
  Stream<QuerySnapshot> getStagingChanges() {
    return _firestore
        .collection(stagingCollection)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Publish all staged changes to their respective collections
  Future<void> publishAllChanges(String adminId) async {
    try {
      final stagedDocs = await _firestore.collection(stagingCollection).get();
      final batch = _firestore.batch();

      for (var doc in stagedDocs.docs) {
        final change = doc.data();
        final String collectionName = change['collection_name'];
        final String docId = change['doc_id'];
        final Map<String, dynamic>? data = change['data'];
        final String changeType = change['change_type'];

        final targetDocRef = _firestore.collection(collectionName).doc(docId);

        switch (changeType) {
          case 'create':
            if (data != null) {
              batch.set(targetDocRef, {
                ...data,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            break;
          case 'update':
            if (data != null) {
              batch.update(targetDocRef, {
                ...data,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            break;
          case 'delete':
            batch.delete(targetDocRef);
            break;
          default:
            debugPrint('Unknown change type: $changeType for doc ${doc.id}');
        }

        // Log the action
        await logAdminAction(
          adminId: adminId,
          action: 'PUBLISH_STAGED_CHANGE',
          targetId: docId,
          targetType: collectionName,
          details:
              'Published staged change: $changeType on $collectionName/$docId',
          metadata: {'staged_doc_id': doc.id, 'change_data': data},
        );
      }

      await batch.commit();

      // Clear the staging collection after successful publish
      await discardAllChanges(
        adminId,
        logDiscard: false,
      ); // Don't log discard again
    } catch (e) {
      throw 'Failed to publish all changes: ${e.toString()}';
    }
  }

  /// Discard all staged changes
  Future<void> discardAllChanges(
    String adminId, {
    bool logDiscard = true,
  }) async {
    try {
      final stagedDocs = await _firestore.collection(stagingCollection).get();
      final batch = _firestore.batch();

      for (var doc in stagedDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (logDiscard) {
        await logAdminAction(
          adminId: adminId,
          action: 'DISCARD_STAGED_CHANGES',
          targetId: 'N/A',
          targetType: 'staging',
          details: 'Discarded all ${stagedDocs.size} staged changes.',
        );
      }
    } catch (e) {
      throw 'Failed to discard all changes: ${e.toString()}';
    }
  }

  /// ========== USER OPERATIONS ==========

  /// Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).set({
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save user profile: ${e.toString()}';
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile: ${e.toString()}';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update user profile: ${e.toString()}';
    }
  }

  /// Update FCM Token for push notifications
  Future<void> updateFcmToken(
    String uid,
    String token, {
    bool isAdmin = false,
  }) async {
    try {
      final collection = isAdmin ? adminsCollection : usersCollection;
      await _firestore.collection(collection).doc(uid).set({
        'fcm_token': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Get admin profile (by UID or email fallback)
  Future<Map<String, dynamic>?> getAdminProfile(
    String adminId, {
    String? email,
  }) async {
    try {
      // Try by UID first (doc ID)
      DocumentSnapshot doc = await _firestore
          .collection(adminsCollection)
          .doc(adminId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }

      // Fallback to email search if provided
      if (email != null) {
        final query = await _firestore
            .collection(adminsCollection)
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          return {
            ...doc.data(),
            'id': doc.id, // Include the actual document ID
          };
        }
      }

      return null;
    } catch (e) {
      throw 'Failed to get admin profile: ${e.toString()}';
    }
  }

  /// Get all admins
  Stream<QuerySnapshot> getAdmins() {
    return _firestore
        .collection(adminsCollection)
        .where('is_active', isEqualTo: true)
        .snapshots();
  }

  /// Add new admin
  Future<void> addAdmin(
    Map<String, dynamic> adminData,
    String performedBy,
  ) async {
    try {
      final docRef = await _firestore.collection(adminsCollection).add({
        ...adminData,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'CREATE_ADMIN',
        targetId: docRef.id,
        targetType: 'admin',
        details:
            'Added new admin: ${adminData['full_name']} (${adminData['email']})',
      );
    } catch (e) {
      throw 'Failed to add admin: ${e.toString()}';
    }
  }

  /// Update admin
  Future<void> updateAdmin({
    required String adminId,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    try {
      await _firestore.collection(adminsCollection).doc(adminId).update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'UPDATE_ADMIN',
        targetId: adminId,
        targetType: 'admin',
        details: 'Updated admin fields: ${updates.keys.join(', ')}',
      );
    } catch (e) {
      throw 'Failed to update admin: ${e.toString()}';
    }
  }

  /// Delete admin (soft delete)
  Future<void> deleteAdmin(String adminId, String performedBy) async {
    try {
      await _firestore.collection(adminsCollection).doc(adminId).update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'DELETE_ADMIN',
        targetId: adminId,
        targetType: 'admin',
        details: 'Soft deleted admin',
      );
    } catch (e) {
      throw 'Failed to delete admin: ${e.toString()}';
    }
  }

  /// ========== AUDIT LOGGING ==========

  /// Log an administrative action
  Future<void> logAdminAction({
    required String adminId,
    required String action, // e.g., 'CREATE_PRODUCT', 'UPDATE_CATEGORY'
    required String targetId,
    required String targetType, // e.g., 'product', 'category'
    required String details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(auditLogsCollection).add({
        'admin_id': adminId,
        'action': action,
        'target_id': targetId,
        'target_type': targetType,
        'details': details,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to log admin action: $e');
      // We don't throw here to avoid failing the main operation if logging fails
    }
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream({
    String? action,
    String? targetType,
    int limit = 100,
  }) {
    Query query = _firestore
        .collection(auditLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (action != null) query = query.where('action', isEqualTo: action);
    if (targetType != null) {
      query = query.where('target_type', isEqualTo: targetType);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? action,
    String? targetType,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(auditLogsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (action != null) query = query.where('action', isEqualTo: action);
      if (targetType != null) {
        query = query.where('target_type', isEqualTo: targetType);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw 'Failed to fetch audit logs: ${e.toString()}';
    }
  }

  /// ========== PRODUCT OPERATIONS ==========

  Stream<QuerySnapshot> getProducts({
    String? category,
    int limit = 20,
    String status = 'published',
  }) {
    Query query = _firestore
        .collection(productsCollection)
        .where('is_active', isEqualTo: true)
        .where('status', isEqualTo: status);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.limit(limit).snapshots();
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection(productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw 'Failed to get product: ${e.toString()}';
    }
  }

  /// Get product (alias for compatibility)
  Future<Product?> getProduct(String productId) async {
    return await getProductById(productId);
  }

  Future<List<Product>> getAllProducts({String status = 'published'}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(productsCollection)
          .where('is_active', isEqualTo: true)
          .where('status', isEqualTo: status)
          .limit(100)
          .get();

      return snapshot.docs
          .map(
            (doc) => Product.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get products: ${e.toString()}';
    }
  }

  Future<List<Product>> getProductsByCategory(
    String category, {
    String status = 'published',
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(productsCollection)
          .where('is_active', isEqualTo: true)
          .where('status', isEqualTo: status)
          .where('category', isEqualTo: category)
          .limit(100)
          .get();

      return snapshot.docs
          .map(
            (doc) => Product.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get products by category: ${e.toString()}';
    }
  }

  /// Upload new product
  Future<String> uploadProduct({
    required String tagNumber,
    required String category,
    required String subcategory,
    required double grossWeight,
    required double netWeight,
    required int purity,
    required List<String> imageUrls,
    required String uploadedBy,
    String? name,
    String? description,
    String status = 'draft',
  }) async {
    try {
      DocumentReference productRef = await _firestore
          .collection(productsCollection)
          .add({
            'tag_number': tagNumber,
            'category': category,
            'subcategory': subcategory,
            'name': name,
            'description': description,
            'image_urls': imageUrls,
            'gross_weight': grossWeight,
            'net_weight': netWeight,
            'purity': purity,
            'uploaded_by': uploadedBy,
            'is_active': true,
            'status': status,
            'version': status == 'published' ? 1 : 0,
            'last_published_at': status == 'published'
                ? FieldValue.serverTimestamp()
                : null,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

      await logAdminAction(
        adminId: uploadedBy,
        action: 'CREATE_PRODUCT',
        targetId: productRef.id,
        targetType: 'product',
        details: 'Created product: $name ($tagNumber)',
        metadata: {'tag_number': tagNumber},
      );

      return productRef.id;
    } catch (e) {
      throw 'Failed to upload product: ${e.toString()}';
    }
  }

  /// Update product
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection(productsCollection).doc(productId).update({
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Note: We'd need adminId here for logging.
      // I'll update the signature to accept performedBy if needed,
      // but for now I'll assume we pass it in updates or as a separate param.
    } catch (e) {
      throw 'Failed to update product: ${e.toString()}';
    }
  }

  /// Update product with logging
  Future<void> updateProductWithLog({
    required String productId,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    try {
      await updateProduct(productId, updates);
      await logAdminAction(
        adminId: performedBy,
        action: 'UPDATE_PRODUCT',
        targetId: productId,
        targetType: 'product',
        details: 'Updated product fields: ${updates.keys.join(', ')}',
      );
    } catch (e) {
      throw 'Failed to update product: ${e.toString()}';
    }
  }

  /// Publish a product (sets status to published and updates version)
  Future<void> publishProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection(productsCollection)
          .doc(productId)
          .get();
      if (!doc.exists) throw 'Product not found';

      final data = doc.data() as Map<String, dynamic>;
      final currentVersion = data['version'] as int? ?? 0;

      await _firestore.collection(productsCollection).doc(productId).update({
        'status': 'published',
        'version': currentVersion + 1,
        'last_published_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // We'll update the caller (UI) to also call logAdminAction for publish
    } catch (e) {
      throw 'Failed to publish product: ${e.toString()}';
    }
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String productId, String performedBy) async {
    try {
      await _firestore.collection(productsCollection).doc(productId).update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'DELETE_PRODUCT',
        targetId: productId,
        targetType: 'product',
        details: 'Soft deleted product',
      );
    } catch (e) {
      throw 'Failed to delete product: ${e.toString()}';
    }
  }

  /// ========== CATEGORY OPERATIONS ==========

  Stream<QuerySnapshot> getCategories({bool onlyActive = true}) {
    Query query = _firestore.collection(categoriesCollection);
    if (onlyActive) {
      query = query.where('is_active', isEqualTo: true);
    }
    return query.snapshots();
  }

  Future<void> addCategory(
    Map<String, dynamic> data,
    String performedBy,
  ) async {
    try {
      final docRef = await _firestore.collection(categoriesCollection).add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'CREATE_CATEGORY',
        targetId: docRef.id,
        targetType: 'category',
        details: 'Added category: ${data['name']}',
      );
    } catch (e) {
      throw 'Failed to add category: ${e.toString()}';
    }
  }

  Future<void> updateCategory({
    required String id,
    required Map<String, dynamic> data,
    required String performedBy,
  }) async {
    try {
      await _firestore.collection(categoriesCollection).doc(id).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'UPDATE_CATEGORY',
        targetId: id,
        targetType: 'category',
        details: 'Updated category: ${data['name'] ?? id}',
      );
    } catch (e) {
      throw 'Failed to update category: ${e.toString()}';
    }
  }

  /// ========== SUBCATEGORY OPERATIONS ==========

  Stream<QuerySnapshot> getSubcategories(
    String? categoryId, {
    bool onlyActive = true,
  }) {
    Query query = _firestore.collection(subcategoriesCollection);
    if (categoryId != null) {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    if (onlyActive) {
      query = query.where('is_active', isEqualTo: true);
    }
    return query.snapshots();
  }

  Future<void> addSubcategory(
    Map<String, dynamic> data,
    String performedBy,
  ) async {
    try {
      final docRef = await _firestore.collection(subcategoriesCollection).add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'CREATE_SUBCATEGORY',
        targetId: docRef.id,
        targetType: 'subcategory',
        details: 'Added subcategory: ${data['name']}',
      );
    } catch (e) {
      throw 'Failed to add subcategory: ${e.toString()}';
    }
  }

  Future<void> updateSubcategory({
    required String id,
    required Map<String, dynamic> data,
    required String performedBy,
  }) async {
    try {
      await _firestore.collection(subcategoriesCollection).doc(id).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'UPDATE_SUBCATEGORY',
        targetId: id,
        targetType: 'subcategory',
        details: 'Updated subcategory: ${data['name'] ?? id}',
      );
    } catch (e) {
      throw 'Failed to update subcategory: ${e.toString()}';
    }
  }

  /// ========== DASHBOARD STATS ==========

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final products = await _firestore.collection(productsCollection).get();
      final categories = await _firestore
          .collection(categoriesCollection)
          .get();
      final subcategories = await _firestore
          .collection(subcategoriesCollection)
          .get();
      final admins = await _firestore.collection(adminsCollection).get();

      return {
        'products': products.size,
        'categories': categories.size,
        'subcategories': subcategories.size,
        'admins': admins.size,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return {'products': 0, 'categories': 0, 'subcategories': 0, 'admins': 0};
    }
  }

  Future<void> updateAdminProfile({
    required String adminId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection(adminsCollection).doc(adminId).update({
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update admin profile: ${e.toString()}';
    }
  }

  Future<Map<String, String?>> getSupportContact() async {
    try {
      // Get super admins first
      final superAdmins = await _firestore
          .collection(adminsCollection)
          .where('role', isEqualTo: 'super')
          .where('is_active', isEqualTo: true)
          .get();

      if (superAdmins.docs.isNotEmpty) {
        final data = superAdmins.docs.first.data();
        return {
          'whatsapp': data['whatsapp_number'] as String?,
          'email': data['email'] as String?,
          'secondary_email': data['secondary_email'] as String?,
          'name': data['full_name'] as String?,
        };
      }

      // Fallback to any active admin
      final anyAdmin = await _firestore
          .collection(adminsCollection)
          .where('is_active', isEqualTo: true)
          .get();

      if (anyAdmin.docs.isNotEmpty) {
        final data = anyAdmin.docs.first.data();
        return {
          'whatsapp': data['whatsapp_number'] as String?,
          'email': data['email'] as String?,
          'secondary_email': data['secondary_email'] as String?,
          'name': data['full_name'] as String?,
        };
      }

      return {'whatsapp': null, 'email': null};
    } catch (e) {
      debugPrint('Error getting support contact: $e');
      return {'whatsapp': null, 'email': null};
    }
  }

  /// ========== CART OPERATIONS ==========

  /// Get user cart items
  Stream<QuerySnapshot> getUserCart(String userId) {
    return _firestore
        .collection(cartItemsCollection)
        .doc(userId)
        .collection('items')
        .snapshots();
  }

  /// Add item to cart
  Future<void> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      await _firestore
          .collection(cartItemsCollection)
          .doc(userId)
          .collection('items')
          .doc(productId)
          .set({
            'productId': productId,
            'quantity': quantity,
            'addedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to add to cart: ${e.toString()}';
    }
  }

  /// Update cart item quantity
  Future<void> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(userId: userId, productId: productId);
      } else {
        await _firestore
            .collection(cartItemsCollection)
            .doc(userId)
            .collection('items')
            .doc(productId)
            .update({'quantity': quantity});
      }
    } catch (e) {
      throw 'Failed to update cart: ${e.toString()}';
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      await _firestore
          .collection(cartItemsCollection)
          .doc(userId)
          .collection('items')
          .doc(productId)
          .delete();
    } catch (e) {
      throw 'Failed to remove from cart: ${e.toString()}';
    }
  }

  /// Clear user cart
  Future<void> clearCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(cartItemsCollection)
          .doc(userId)
          .collection('items')
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw 'Failed to clear cart: ${e.toString()}';
    }
  }

  /// Get cart items as list (for CartProvider)
  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(cartItemsCollection)
          .doc(userId)
          .collection('items')
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw 'Failed to get cart items: ${e.toString()}';
    }
  }

  /// Update entire cart (for CartProvider)
  Future<void> updateCart(
    String userId,
    List<Map<String, dynamic>> cartData,
  ) async {
    try {
      // Clear existing cart
      await clearCart(userId);

      // Add new items
      WriteBatch batch = _firestore.batch();
      for (var item in cartData) {
        DocumentReference itemRef = _firestore
            .collection(cartItemsCollection)
            .doc(userId)
            .collection('items')
            .doc(item['productId']);

        batch.set(itemRef, item);
      }

      await batch.commit();
    } catch (e) {
      throw 'Failed to update cart: ${e.toString()}';
    }
  }

  /// ========== ORDER OPERATIONS ==========

  /// Create order (updated signature for OrderProvider)
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    try {
      DocumentReference orderRef = await _firestore
          .collection(ordersCollection)
          .add({
            ...orderData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return orderRef.id;
    } catch (e) {
      throw 'Failed to create order: ${e.toString()}';
    }
  }

  /// Get user orders
  Stream<QuerySnapshot> getUserOrders(String userId) {
    return _firestore
        .collection(ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get orders as list (for OrderProvider)
  Future<List<app_order.Order>> getOrders(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(ordersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map(
            (doc) => app_order.Order.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get orders: ${e.toString()}';
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection(ordersCollection).doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update order status: ${e.toString()}';
    }
  }

  /// Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw 'Failed to get order: ${e.toString()}';
    }
  }

  /// ========== SAMPLE ORDER OPERATIONS ==========

  /// Place a custom sample order
  Future<Map<String, String>> placeSampleOrder(
    Map<String, dynamic> sampleOrderData,
    List<File> imageFiles, {
    String category = 'general',
  }) async {
    try {
      // Sanitise category for use as a Storage folder name
      final safeCategory = category.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9_]'),
        '_',
      );
      final storageFolder = 'sample_orders/$safeCategory';

      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < imageFiles.length; i++) {
          // Append index to guarantee a unique path even when multiple
          // uploads happen within the same millisecond.
          final fileName = 'design_${baseTimestamp}_$i';
          final url = await uploadImage(
            imageFile: imageFiles[i],
            folder: storageFolder,
            fileName: fileName,
          );
          imageUrls.add(url);
        }
      }

      final docRef = await _firestore.collection(sampleOrdersCollection).add({
        ...sampleOrderData,
        // Explicit fields always override whatever toJson() sends
        'category': category,
        'imageUrls': imageUrls,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'docId': docRef.id,
        'imageUrls': imageUrls.join(','), // Join with comma for easy extraction
      };
    } catch (e) {
      throw 'Failed to place sample order: ${e.toString()}';
    }
  }

  /// ========== STORAGE OPERATIONS ==========

  /// Upload image to Firebase Storage
  Future<String> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
  }) async {
    // 1. Verify file exists
    if (!await imageFile.exists()) {
      debugPrint('❌ Upload error: File does not exist at ${imageFile.path}');
      throw 'Image file not found on device';
    }

    String name = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      // 2. Check Auth (Lazy Sign-in)
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('⚠️ User is null. Attempting anonymous sign-in...');
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (authError) {
          debugPrint('❌ Anonymous sign-in failed: $authError');
        }
      }

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      String fullPath = '$folder/$name.jpg';
      debugPrint(
        'ℹ️ Uploading ${await imageFile.length()} bytes to path: $fullPath',
      );

      Reference ref = _storage.ref().child(fullPath);

      // 3. Perform upload
      UploadTask task = ref.putFile(imageFile, metadata);

      // Listen to progress for debugging
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint('📤 Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        // Robust Download URL fetch with retry (handles Storage race conditions)
        String downloadUrl = '';
        int retryCount = 0;
        while (retryCount < 3) {
          try {
            downloadUrl = await ref.getDownloadURL();
            break;
          } catch (e) {
            retryCount++;
            if (retryCount >= 3) rethrow;
            debugPrint('⚠️ getDownloadURL retry $retryCount due to: $e');
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
        debugPrint('✅ Upload success. URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw 'Upload task ended with state: ${snapshot.state}';
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase Storage Error: [${e.code}] ${e.message}');
      debugPrint('❌ Full error details: $e');
      throw 'Storage error (${e.code}): ${e.message}';
    } catch (e) {
      debugPrint('❌ Unexpected upload error: $e');
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    List<String> imageUrls = [];
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        // Unique name per image: timestamp_index
        String fileName = '${timestamp}_$i';
        String url = await uploadImage(
          imageFile: imageFiles[i],
          folder: folder,
          fileName: fileName,
        );
        imageUrls.add(url);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        // Continue with other images or throw if critical
      }
    }
    return imageUrls;
  }

  /// ========== RECENT VIEWS ==========

  /// Add product to recent views
  Future<void> addToRecentViews({
    required String userId,
    required String productId,
  }) async {
    try {
      await _firestore
          .collection(recentViewsCollection)
          .doc('${userId}_$productId')
          .set({
            'userId': userId,
            'productId': productId,
            'viewedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Silently fail for recent views
    }
  }

  /// Get recent views
  Stream<QuerySnapshot> getRecentViews(String userId, {int limit = 30}) {
    return _firestore
        .collection(recentViewsCollection)
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .snapshots();
  }

  /// ========== WHOLESALER UPLOADS ==========

  /// Create wholesaler upload
  Future<String> createWholesalerUpload({
    required String userId,
    required Map<String, dynamic> uploadData,
  }) async {
    try {
      DocumentReference uploadRef = await _firestore
          .collection(wholesalerUploadsCollection)
          .add({
            ...uploadData,
            'userId': userId,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      return uploadRef.id;
    } catch (e) {
      throw 'Failed to create upload: ${e.toString()}';
    }
  }

  /// Get user uploads
  Stream<QuerySnapshot> getUserUploads(String userId) {
    return _firestore
        .collection(wholesalerUploadsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ========== STORAGE OPERATIONS ==========

  /// Upload product image
  Future<String> uploadProductImage(String fileName, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child('products/$fileName');
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload product image: ${e.toString()}';
    }
  }

  /// Upload user avatar
  Future<String> uploadUserAvatar(
    String userId,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final ref = _storage.ref().child('avatars/$userId/$fileName');
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload avatar: ${e.toString()}';
    }
  }

  /// Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Failed to delete image: $e');
    }
  }

  /// ========== SEEDING INITIAL DATA ==========
  /// Populate Firestore with product categories and sample products based on original app
  Future<void> seedInitialData() async {
    try {
      // Note: Skipping duplicate check temporarily to ensure all subcategories are filled
      /*
      final existingProducts = await _firestore
          .collection(productsCollection)
          .limit(1)
          .get();
      if (existingProducts.docs.isNotEmpty) {
        debugPrint('Data already seeded. Skipping.');
        return;
      }
      */

      // Seed Super Admin first
      await seedSuperAdmin();

      final List<String> subcategories84 = [
        'Latkan 84M',
        'Mangalsutra 84M',
        'MS Dokiya 84M',
        'MS Pendal 84M',
        'Najariya 84M',
        'Najrana Ring 84M',
        'Nath 84M',
        'Patla 84M',
        'R Ladies Ring 84',
        'Round Gents Ring 84',
        'Rudraksh 84M',
        'Salman Bali 84M',
        'Set 84M',
        'Setbutty 84',
        'Step Butty 84',
        'Surya Pendal 84',
        'Tika 84M',
        'UV Bali 84',
        'Vertical Butty 84',
        'Vertical Dokiya 84M',
        'Zummar 84',
        'Zummar Butty 84',
        'Bachha Lucky 84M',
        'Bajubandh 84M',
        'Bali 84',
        'Butty 84',
        'China Butty 84',
        'Fancy Kadi 84',
        'Gents Ring 84',
        'Gol Butty 84',
        'J Butty 84',
        'Kanser 84M',
        'Kayda 84',
        'Ladies Lucky 84M',
        'Ladies Pendal 84M',
        'Ladies Ring 84',
        'Lappa Har 84',
      ];

      final List<String> subcategories92 = [
        'Antiq Butty 92',
        'Antique Dokiya 92',
        'Bachhalucky 92M',
        'Bajubandh 92M',
        'Bali 92M',
        'Butty 92M',
        'China Butty 92',
        'CZ Butty 92',
        'CZ Gents Ring 92',
        'CZ Ladies Ring 92',
        'CZ MSP 92',
        'CZ Pandal Butty Set',
        'Fancy Kadi 92',
        'Gents Ring 92M',
        'Gol Butty 92',
        'J Butty 92',
        'Kanser 92M',
        'Kayda 92',
        'Keri Butty 92',
        'Ladies Lucky 92M',
        'Ladies Pendal 92M',
        'Long Ring 92',
        'Long Set 92',
        'Mangalsutra 92M',
        'MS Dokiya 92M',
        'MS Pendal 92M',
        'Najariya 92M',
        'Najrana Ring 92',
        'P. Casting GR',
        'P. Casting LR',
        'Patla 92M',
        'R Ladies Ring 92',
        'Rudraksh 92M',
        'Set 92M',
        'Setbutty 92',
        'Step Butty 92',
        'Surya Pendal 92M',
        'Tika 92M',
        'UV Bali 92',
        'Vertical Butty 92',
        'Vertical Dokiya 92M',
        'Zummar 92M',
        'Zummar Butty 92',
      ];

      final List<String> subcategoriesChains = [
        'Handmade Chain 92M',
        'Hollow 92M',
        'Hollow Lucky 92M',
        'Indo Hollow 92M',
        'Lotus 92M',
        'Nice Chain 92M',
        'Silky 92M',
        'Singapuri 92M',
      ];

      final batch = _firestore.batch();
      int count = 0;

      final List<String> localAssets = [
        'assets/images/ring.webp',
        'assets/images/bangles.png',
        'assets/images/chain.webp',
        'assets/images/earrings.png',
        'assets/images/necklaces.png',
        'assets/images/bracelets.png',
        'assets/images/gold_chain.png',
      ];

      String getAssetForSubcategory(String name) {
        final lower = name.toLowerCase();
        if (lower.contains('ring')) return 'assets/images/ring.webp';
        if (lower.contains('bangle') || lower.contains('patla')) {
          return 'assets/images/bangles.png';
        }
        if (lower.contains('chain')) return 'assets/images/chain.webp';
        if (lower.contains('bali') ||
            lower.contains('butty') ||
            lower.contains('earring')) {
          return 'assets/images/earrings.png';
        }
        if (lower.contains('set') ||
            lower.contains('har') ||
            lower.contains('neck')) {
          return 'assets/images/necklaces.png';
        }
        if (lower.contains('lucky') ||
            lower.contains('bracelet') ||
            lower.contains('kadi')) {
          return 'assets/images/bracelets.png';
        }
        // Fallback to random if no keyword match
        return localAssets[DateTime.now().millisecond % localAssets.length];
      }

      // Step 1: Create Categories
      final List<Map<String, String>> categories = [
        {'id': '84_melting', 'name': '84 Melting (84.00)'},
        {'id': '92_melting', 'name': '92 Melting (91.66 / 22K)'},
        {'id': '92_melting_chains', 'name': '92 Melting Chains'},
      ];

      for (var cat in categories) {
        final catRef = _firestore
            .collection(categoriesCollection)
            .doc(cat['id']);
        batch.set(catRef, {
          'name': cat['name'],
          'image_url': 'assets/logo.png', // Default image for categories
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      void addProductsForSubcategory(
        String category,
        String categoryId,
        String subcategory,
        int purity,
      ) {
        // 1. Create Subcategory record
        final asset = getAssetForSubcategory(subcategory);
        final subRef = _firestore.collection(subcategoriesCollection).doc();
        batch.set(subRef, {
          'name': subcategory,
          'category_id': categoryId,
          'image_url': asset, // Use subcategory asset as its image
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // 2. Add products
        for (int i = 1; i <= 2; i++) {
          final docRef = _firestore.collection(productsCollection).doc();
          final product = {
            'tag_number':
                '${subcategory.replaceAll(' ', '').toUpperCase().padRight(3, 'X').substring(0, 3)}-$category-$purity-$i-${count + i}',
            'category': categoryId, // Consistent with updated model
            'subcategory': subcategory,
            'name': '$subcategory ${i == 1 ? "Premium" : "Classic"} Design',
            'description':
                'Exquisite $subcategory from our $category collection. Crafted with $purity% purity gold.',
            'image_urls': [asset],
            'gross_weight': (5.0 + (i * 2.5)).toDouble(),
            'net_weight': (4.8 + (i * 2.5)).toDouble(),
            'purity': purity,
            'uploaded_by': 'admin_seeder',
            'is_active': true,
            'status': 'published', // New status for versioning
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          batch.set(docRef, product);
          count++;
        }
      }

      for (var sub in subcategories84) {
        addProductsForSubcategory('84 Melting', '84_melting', sub, 84);
      }
      for (var sub in subcategories92) {
        addProductsForSubcategory('92 Melting', '92_melting', sub, 92);
      }
      for (var sub in subcategoriesChains) {
        addProductsForSubcategory(
          '92 Melting Chains',
          '92_melting_chains',
          sub,
          92,
        );
      }

      await batch.commit();
      debugPrint('Seeded $count products across all categories.');
    } catch (e) {
      debugPrint('Failed to seed initial data: $e');
    }
  }

  /// ========== WISHLIST OPERATIONS ==========

  /// Get user wishlist items
  Future<List<Map<String, dynamic>>> getWishlistItems(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(wishlistItemsCollection)
          .doc(userId)
          .collection('items')
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw 'Failed to get wishlist items: ${e.toString()}';
    }
  }

  /// Update wishlist
  Future<void> updateWishlist(
    String userId,
    List<Map<String, dynamic>> wishlistData,
  ) async {
    try {
      // Clear existing wishlist items
      final existingItems = await _firestore
          .collection(wishlistItemsCollection)
          .doc(userId)
          .collection('items')
          .get();

      final batch = _firestore.batch();
      for (var doc in existingItems.docs) {
        batch.delete(doc.reference);
      }

      // Add new items
      for (var item in wishlistData) {
        final docRef = _firestore
            .collection(wishlistItemsCollection)
            .doc(userId)
            .collection('items')
            .doc(item['productId']);
        batch.set(docRef, item);
      }

      await batch.commit();
    } catch (e) {
      throw 'Failed to update wishlist: ${e.toString()}';
    }
  }

  /// Seed a default super admin if none exists
  Future<void> seedSuperAdmin() async {
    try {
      // We search by email to see if a super admin already exists
      final result = await _firestore
          .collection(adminsCollection)
          .where('email', isEqualTo: 'admin@vishalgold.com')
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        // Create a default super admin document
        await _firestore.collection(adminsCollection).add({
          'full_name': 'Vishal Gold Admin',
          'email': 'admin@vishalgold.com',
          'role': 'super',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Super Admin seeded successfully.');
      }
    } catch (e) {
      debugPrint('Failed to seed super admin: $e');
    }
  }

  /// ========== MARKET & ANALYTICS ==========

  /// Get live market settings
  Stream<MarketSettings?> getMarketSettings() {
    return _firestore
        .collection(marketSettingsCollection)
        .doc('global')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return MarketSettings.fromJson(doc.data() as Map<String, dynamic>);
          }
          return null;
        });
  }

  /// Update market settings with audit log
  Future<void> updateMarketSettings({
    required MarketSettings settings,
    required String performedBy,
  }) async {
    try {
      await _firestore
          .collection(marketSettingsCollection)
          .doc('global')
          .set(settings.toJson());

      await logAdminAction(
        adminId: performedBy,
        action: 'UPDATE_MARKET_SETTINGS',
        targetId: 'global',
        targetType: 'market_settings',
        details:
            'Updated Gold Rates: 24K: ${settings.goldRate24K}, 22K: ${settings.goldRate22K}, 18K: ${settings.goldRate18K}',
      );
    } catch (e) {
      throw 'Failed to update market settings: ${e.toString()}';
    }
  }

  /// Get weight analytics (Total net weight per category)
  Future<Map<String, double>> getWeightAnalytics() async {
    try {
      final snapshot = await _firestore
          .collection(productsCollection)
          .where('status', isEqualTo: 'published')
          .get();

      final Map<String, double> analytics = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoryId = data['category'] as String?;
        final netWeight = (data['net_weight'] ?? 0.0).toDouble();

        if (categoryId != null) {
          analytics[categoryId] = (analytics[categoryId] ?? 0.0) + netWeight;
        }
      }

      return analytics;
    } catch (e) {
      throw 'Failed to get weight analytics: ${e.toString()}';
    }
  }

  /// Bulk update products
  Future<void> bulkUpdateProducts({
    required List<String> productIds,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      final Map<String, dynamic> finalUpdates = {
        ...updates,
        'updated_at': Timestamp.fromDate(now),
      };

      for (var id in productIds) {
        final docRef = _firestore.collection(productsCollection).doc(id);
        batch.update(docRef, finalUpdates);
      }

      await batch.commit();

      await logAdminAction(
        adminId: performedBy,
        action: 'BULK_UPDATE_PRODUCTS',
        targetId: 'multiple',
        targetType: 'products',
        details:
            'Updated ${productIds.length} products with: ${updates.keys.join(', ')}',
      );
    } catch (e) {
      throw 'Failed to bulk update products: ${e.toString()}';
    }
  }

  /// ========== BANNER MANAGEMENT ==========

  /// Get active banners
  Stream<List<AppBanner>> getActiveBanners() {
    return _firestore
        .collection(bannersCollection)
        .where('is_active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppBanner.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get all banners (for admin)
  Stream<List<AppBanner>> getAllBanners() {
    return _firestore
        .collection(bannersCollection)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppBanner.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Add new banner
  Future<void> addBanner(AppBanner banner, String performedBy) async {
    try {
      final docRef = await _firestore
          .collection(bannersCollection)
          .add(banner.toJson());

      await logAdminAction(
        adminId: performedBy,
        action: 'ADD_BANNER',
        targetId: docRef.id,
        targetType: 'banner',
        details: 'Added banner: ${banner.title ?? 'No Title'}',
      );
    } catch (e) {
      throw 'Failed to add banner: ${e.toString()}';
    }
  }

  /// Update banner
  Future<void> updateBanner(AppBanner banner, String performedBy) async {
    try {
      await _firestore
          .collection(bannersCollection)
          .doc(banner.id)
          .update(banner.toJson());

      await logAdminAction(
        adminId: performedBy,
        action: 'UPDATE_BANNER',
        targetId: banner.id,
        targetType: 'banner',
        details: 'Updated banner: ${banner.title ?? 'No Title'}',
      );
    } catch (e) {
      throw 'Failed to update banner: ${e.toString()}';
    }
  }

  /// Delete banner
  Future<void> deleteBanner(String bannerId, String performedBy) async {
    try {
      await _firestore.collection(bannersCollection).doc(bannerId).delete();

      await logAdminAction(
        adminId: performedBy,
        action: 'DELETE_BANNER',
        targetId: bannerId,
        targetType: 'banner',
        details: 'Deleted banner: $bannerId',
      );
    } catch (e) {
      throw 'Failed to delete banner: ${e.toString()}';
    }
  }

  /// ========== NOTIFICATION OPERATIONS ==========

  Future<void> sendNotificationRequest({
    required Map<String, dynamic> notificationData,
    required String performedBy,
  }) async {
    try {
      final docRef = await _firestore.collection(notificationsCollection).add({
        ...notificationData,
        'createdBy': performedBy,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      await logAdminAction(
        adminId: performedBy,
        action: 'SEND_NOTIFICATION_REQUEST',
        targetId: docRef.id,
        targetType: 'notification',
        details: 'Requested push notification: ${notificationData['title']}',
      );
    } catch (e) {
      throw 'Failed to send notification request: ${e.toString()}';
    }
  }

  /// ========== ANALYTICS ENHANCEMENTS ==========

  Future<List<Map<String, dynamic>>> getTrendingProducts({
    int limit = 5,
  }) async {
    try {
      // Use collectionGroup to query all 'items' subcollections under 'wishlist_items'
      final snapshot = await _firestore.collectionGroup('items').get();

      final Map<String, int> productCounts = {};
      final Map<String, Map<String, dynamic>> productData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        final productMap = data['product'] as Map<String, dynamic>?;
        if (productId != null && productMap != null) {
          productCounts[productId] = (productCounts[productId] ?? 0) + 1;
          if (!productData.containsKey(productId)) {
            productData[productId] = productMap;
          }
        }
      }

      final List<Map<String, dynamic>> trending = productCounts.entries.map((
        e,
      ) {
        return {
          'productId': e.key,
          'wishlistCount': e.value,
          'product': productData[e.key],
        };
      }).toList();

      // Sort by count descending
      trending.sort(
        (a, b) =>
            (b['wishlistCount'] as int).compareTo(a['wishlistCount'] as int),
      );

      return trending.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting trending products: $e');
      return [];
    }
  }
}
