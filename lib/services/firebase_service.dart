import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/order.dart' as app_order;

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

  /// ========== PRODUCT OPERATIONS ==========

  /// Get all products
  Stream<QuerySnapshot> getProducts({String? category, int limit = 20}) {
    Query query = _firestore
        .collection(productsCollection)
        .where('is_active', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.limit(limit).snapshots();
  }

  /// Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw 'Failed to get product: ${e.toString()}';
    }
  }

  /// Get product (alias for compatibility)
  Future<Map<String, dynamic>?> getProduct(String productId) async {
    return await getProductById(productId);
  }

  /// Get all products as a list
  Future<List<Product>> getAllProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(productsCollection)
          .where('is_active', isEqualTo: true)
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

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(productsCollection)
          .where('is_active', isEqualTo: true)
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
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

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
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to update product: ${e.toString()}';
    }
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(productsCollection).doc(productId).update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to delete product: ${e.toString()}';
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
  Future<String> placeSampleOrder(
    Map<String, dynamic> sampleOrderData,
    File? imageFile,
  ) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(
          imageFile: imageFile,
          folder: 'sample_orders',
        );
      }

      final docRef = await _firestore.collection(sampleOrdersCollection).add({
        ...sampleOrderData,
        if (imageUrl != null) 'imageUrls': [imageUrl],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
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
    String name = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      // 1. Check Auth (Lazy Sign-in)
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('⚠️ User is null. Attempting anonymous sign-in...');
        try {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint(
            '✅ Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}',
          );
        } catch (authError) {
          debugPrint('❌ Anonymous sign-in failed: $authError');
        }
      }

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      String fullPath = '$folder/$name';
      debugPrint('ℹ️ Uploading to path: $fullPath');

      // 2. Use putFile for better reliability
      Reference ref = _storage.ref().child(fullPath);
      UploadTask task = ref.putFile(imageFile, metadata);

      // Await the task to ensure completion
      TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        String downloadUrl = await ref.getDownloadURL();
        debugPrint('✅ Upload success. URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw 'Upload task failed with state: ${snapshot.state}';
      }
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    try {
      List<String> urls = [];
      for (File file in imageFiles) {
        String url = await uploadImage(imageFile: file, folder: folder);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw 'Failed to upload images: ${e.toString()}';
    }
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
        if (lower.contains('bangle') || lower.contains('patla'))
          return 'assets/images/bangles.png';
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

      void addProductsForSubcategory(
        String category,
        String subcategory,
        int purity,
      ) {
        final asset = getAssetForSubcategory(subcategory);
        for (int i = 1; i <= 2; i++) {
          final docRef = _firestore.collection(productsCollection).doc();
          final product = {
            'tag_number':
                '${subcategory.replaceAll(' ', '').toUpperCase().padRight(3, 'X').substring(0, 3)}-$category-$purity-$i-${count + i}',
            'category': category,
            'subcategory': subcategory,
            'name': '$subcategory ${i == 1 ? "Premium" : "Classic"} Design',
            'description':
                'Exquisite $subcategory from our $category collection. Crafted with $purity% purity gold, this ${i == 1 ? "premium" : "classic"} piece features intricate detailing and a superior finish.',
            'image_urls': [asset],
            'gross_weight': (5.0 + (i * 2.5) + (subcategory.length % 5))
                .toDouble(),
            'net_weight': (4.8 + (i * 2.5) + (subcategory.length % 5))
                .toDouble(),
            'purity': purity,
            'uploaded_by': 'admin_seeder',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          batch.set(docRef, product);
          count++;
        }
      }

      for (var sub in subcategories84) {
        addProductsForSubcategory('84_melting', sub, 84);
      }
      for (var sub in subcategories92) {
        addProductsForSubcategory('92_melting', sub, 92);
      }
      for (var sub in subcategoriesChains) {
        addProductsForSubcategory('92_melting_chains', sub, 92);
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
}
