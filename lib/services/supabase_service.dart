import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vishal_gold/config/app_config.dart';
import 'package:vishal_gold/models/user.dart' as app_models;
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/cart_item.dart';
import 'package:vishal_gold/models/order.dart';
import 'package:vishal_gold/models/notification.dart' as app_models;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  // Initialize Supabase
  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Auth Methods
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user != null) {
      // Try to insert user profile - may fail if email confirmation is required
      // or due to RLS policies, but that's okay - profile will be created on first login
      try {
        await _client.from('users').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Profile creation might fail if user already exists or due to RLS
        // This is non-critical - profile can be created later
        print('Profile creation deferred: $e');
      }
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // User Profile Methods
  Future<app_models.User?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return app_models.User.fromJson(response);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('users').update(data).eq('id', userId);
  }

  Future<void> saveUserRole(String userId, String role) async {
    await _client
        .from('users')
        .update({
          'user_type': role,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  Future<void> saveCompanyDetails({
    required String userId,
    required String companyName,
    required String address,
    required String city,
  }) async {
    await _client
        .from('users')
        .update({
          'company_name': companyName,
          'company_address': address,
          'city': city,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Product Methods
  Future<List<Product>> fetchProducts({
    String? category,
    String? subcategory,
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('products').select().eq('is_active', true);

    // Apply conditional filters before range
    if (category != null) {
      query = query.eq('category', category);
    }
    if (subcategory != null) {
      query = query.eq('subcategory', subcategory);
    }

    // Apply ordering and range at the end
    query = query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final response = await query;
    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProduct(String productId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  // Cart Methods
  Future<List<CartItem>> getCartItems(String userId) async {
    final response = await _client
        .from('cart_items')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('added_at', ascending: false);

    return (response as List).map((json) => CartItem.fromJson(json)).toList();
  }

  Future<void> addToCart(String userId, String productId) async {
    // Check if already in cart
    final existing = await _client
        .from('cart_items')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      // Increment quantity
      await _client
          .from('cart_items')
          .update({'quantity': existing['quantity'] + 1})
          .eq('id', existing['id']);
    } else {
      // Insert new
      await _client.from('cart_items').insert({
        'user_id': userId,
        'product_id': productId,
        'quantity': 1,
        'added_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  Future<void> clearCart(String userId) async {
    await _client.from('cart_items').delete().eq('user_id', userId);
  }

  // Order Methods
  Future<Order> placeOrder(String userId, List<CartItem> cartItems) async {
    final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    // Create order
    final orderResponse = await _client
        .from('orders')
        .insert({
          'user_id': userId,
          'order_number': orderNumber,
          'status': 'pending',
          'total_items': cartItems.length,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final order = Order.fromJson(orderResponse);

    // Create order items
    for (var item in cartItems) {
      if (item.product != null) {
        await _client.from('order_items').insert({
          'order_id': order.id,
          'product_id': item.productId,
          'quantity': item.quantity,
          'tag_number': item.product!.tagNumber,
          'gross_weight': item.product!.grossWeight,
          'net_weight': item.product!.netWeight,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    // Clear cart
    await clearCart(userId);

    // Send admin notification
    await _client.from('admin_notifications').insert({
      'type': 'new_order',
      'order_id': order.id,
      'message': 'New order $orderNumber received',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    return order;
  }

  Future<List<Order>> getOrders(String userId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  // Alias for getOrders to match usage in screens
  Future<List<Order>> getUserOrders(String userId) async {
    return getOrders(userId);
  }

  Future<Order?> getOrder(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(response);
  }

  // Notification Methods
  Future<List<app_models.AppNotification>> getNotifications(
    String userId,
  ) async {
    final response = await _client
        .from('notifications')
        .select()
        .or('user_id.eq.$userId,user_id.is.null')
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => app_models.AppNotification.fromJson(json))
        .toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  // Recent Views Methods
  Future<void> trackRecentView(String userId, String productId) async {
    // Check if already in recent views
    final existing = await _client
        .from('recent_views')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      // Update timestamp
      await _client
          .from('recent_views')
          .update({'viewed_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      // Insert new
      await _client.from('recent_views').insert({
        'user_id': userId,
        'product_id': productId,
        'viewed_at': DateTime.now().toIso8601String(),
      });
    }

    // Keep only last 30 views
    await _cleanupOldViews(userId);
  }

  Future<void> _cleanupOldViews(String userId) async {
    final allViews = await _client
        .from('recent_views')
        .select()
        .eq('user_id', userId)
        .order('viewed_at', ascending: false);

    if (allViews.length > AppConfig.maxRecentViews) {
      final oldViews = allViews.skip(AppConfig.maxRecentViews).toList();
      for (var view in oldViews) {
        await _client.from('recent_views').delete().eq('id', view['id']);
      }
    }
  }

  Future<List<Product>> getRecentViews(String userId) async {
    final response = await _client
        .from('recent_views')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(30);

    return (response as List)
        .where((item) => item['products'] != null)
        .map((item) => Product.fromJson(item['products']))
        .toList();
  }

  // Alias for getRecentViews to match usage in screens
  Future<List<Product>> getRecentlyViewedProducts(String userId) async {
    return getRecentViews(userId);
  }

  Future<void> clearRecentViews(String userId) async {
    await _client.from('recent_views').delete().eq('user_id', userId);
  }

  // Wholesaler Upload Methods
  Future<void> uploadDesign({
    required String userId,
    required List<String> imageUrls,
    String? description,
    String? category,
    String? itemName,
    String? quantity,
    String? size,
    String? weightPerQty,
    String? total,
  }) async {
    // Generate a unique tag number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tagPrefix = category == '84_ornaments'
        ? '84U'
        : category == '92_ornaments'
        ? '92U'
        : '92CU';
    final tagNumber =
        '$tagPrefix${timestamp.toString().substring(timestamp.toString().length - 6)}';

    // Parse weights - default to 0 if not provided or invalid
    double grossWeight = 0.0;
    double netWeight = 0.0;
    try {
      // Remove 'g' suffix and parse
      final totalStr = total?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
      final wtPerQtyStr =
          weightPerQty?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
      grossWeight = double.tryParse(totalStr) ?? 0.0;
      if (grossWeight == 0.0) {
        grossWeight = double.tryParse(wtPerQtyStr) ?? 0.0;
      }
      netWeight = grossWeight * 0.95; // Assume 5% less for net weight
    } catch (_) {
      // Silently handle parsing errors
    }

    // Determine purity from category
    final purity = category?.contains('84') == true ? 84 : 92;

    // Determine subcategory based on item name or default
    String subcategory = itemName ?? 'Other';

    // Store in wholesaler_uploads for tracking
    await _client.from('wholesaler_uploads').insert({
      'user_id': userId,
      'image_urls': imageUrls,
      'description': description,
      'category': category,
      'item_name': itemName,
      'quantity': quantity,
      'size': size,
      'weight_per_qty': weightPerQty,
      'total': total,
      'status': 'approved', // Auto-approve for now
      'created_at': DateTime.now().toIso8601String(),
    });

    // Also insert directly into products table so it shows in the listing
    await _client.from('products').insert({
      'tag_number': tagNumber,
      'category': category ?? '84_ornaments',
      'subcategory': subcategory,
      'name': itemName,
      'description': description,
      'image_urls': imageUrls,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'purity': purity,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Notify admin
    await _client.from('admin_notifications').insert({
      'type': 'new_upload',
      'message':
          'New design upload: ${itemName ?? 'Untitled'} in ${category ?? 'Unknown category'}',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Alias for uploadDesign to match usage in screens
  Future<void> createWholesalerUpload({
    required String userId,
    required List<String> imageUrls,
    String? description,
    String? category,
    String? itemName,
    String? quantity,
    String? size,
    String? weightPerQty,
    String? total,
  }) async {
    return uploadDesign(
      userId: userId,
      imageUrls: imageUrls,
      description: description,
      category: category,
      itemName: itemName,
      quantity: quantity,
      size: size,
      weightPerQty: weightPerQty,
      total: total,
    );
  }

  // Storage Methods
  /// Upload an image to the 'uploads' bucket (for design uploads)
  Future<String> uploadImage(String path, List<int> bytes) async {
    final userId = currentUserId ?? 'anonymous';
    final fileName =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
    final uint8List = Uint8List.fromList(bytes);

    await _client.storage
        .from('uploads')
        .uploadBinary(
          fileName,
          uint8List,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
    return _client.storage.from('uploads').getPublicUrl(fileName);
  }

  /// Upload a profile avatar image
  Future<String> uploadAvatar(
    String userId,
    List<int> bytes,
    String fileName,
  ) async {
    final extension = fileName.split('.').last;
    final filePath =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final uint8List = Uint8List.fromList(bytes);

    await _client.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          uint8List,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true, // Replace existing avatar
          ),
        );
    return _client.storage.from('avatars').getPublicUrl(filePath);
  }

  /// Upload multiple images to the uploads bucket
  Future<List<String>> uploadMultipleImages(
    List<Map<String, dynamic>> images,
  ) async {
    final List<String> urls = [];
    final userId = currentUserId ?? 'anonymous';

    for (var image in images) {
      final bytes = image['bytes'] as List<int>;
      final path = image['path'] as String;
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final uint8List = Uint8List.fromList(bytes);

      await _client.storage
          .from('uploads')
          .uploadBinary(
            fileName,
            uint8List,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      urls.add(_client.storage.from('uploads').getPublicUrl(fileName));
    }
    return urls;
  }

  /// Delete an image from a specific bucket
  Future<void> deleteImage(String bucket, String filePath) async {
    await _client.storage.from(bucket).remove([filePath]);
  }

  /// Get signed URL for temporary access to a private file
  Future<String> getSignedUrl(
    String bucket,
    String filePath, {
    int expiresIn = 3600,
  }) async {
    final response = await _client.storage
        .from(bucket)
        .createSignedUrl(filePath, expiresIn);
    return response;
  }

  // Policy Methods
  Future<Map<String, dynamic>?> getPolicy(String type) async {
    final response = await _client
        .from('policies')
        .select()
        .eq('type', type)
        .maybeSingle();

    return response;
  }
}
