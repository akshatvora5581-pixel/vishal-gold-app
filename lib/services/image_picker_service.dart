import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vishal_gold/services/supabase_service.dart';

/// A service to handle image picking and uploading
class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();

  /// Pick a single image from gallery or camera
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? 85,
        limit: limit,
      );
      return images;
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Pick and upload a single image, returns the URL
  Future<String?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    final image = await pickImage(
      source: source,
      maxWidth: maxWidth ?? 1920,
      maxHeight: maxHeight ?? 1920,
      imageQuality: imageQuality ?? 85,
    );

    if (image == null) return null;

    try {
      final bytes = await image.readAsBytes();
      final url = await _supabaseService.uploadImage(image.path, bytes);
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Pick and upload multiple images, returns list of URLs
  Future<List<String>> pickAndUploadMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
    void Function(int current, int total)? onProgress,
  }) async {
    final images = await pickMultipleImages(
      maxWidth: maxWidth ?? 1920,
      maxHeight: maxHeight ?? 1920,
      imageQuality: imageQuality ?? 85,
      limit: limit,
    );

    if (images.isEmpty) return [];

    final List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      try {
        onProgress?.call(i + 1, images.length);
        final bytes = await images[i].readAsBytes();
        final url = await _supabaseService.uploadImage(images[i].path, bytes);
        urls.add(url);
      } catch (e) {
        debugPrint('Error uploading image ${i + 1}: $e');
      }
    }
    return urls;
  }

  /// Upload an avatar image for a user
  Future<String?> pickAndUploadAvatar({
    required String userId,
    ImageSource source = ImageSource.gallery,
  }) async {
    final image = await pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );

    if (image == null) return null;

    try {
      final bytes = await image.readAsBytes();
      final fileName = image.path.split('/').last;
      final url = await _supabaseService.uploadAvatar(userId, bytes, fileName);
      return url;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Show a bottom sheet to choose image source
  Future<ImageSource?> showImageSourcePicker(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Choose Image Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from your photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
