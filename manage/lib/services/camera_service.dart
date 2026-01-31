import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

/// Check if the current platform supports camera
bool get _isCameraSupportedPlatform {
  // Camera is supported on mobile and desktop, but not fully on web
  if (kIsWeb) return true; // Web uses file picker fallback
  try {
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;
  } catch (e) {
    return false;
  }
}

/// Service for capturing and managing animal photos
class CameraService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _client = SupabaseConfig.client;
  final _uuid = const Uuid();
  static const String _bucketName = 'animal-photos';

  /// Check if camera is available (not available on web)
  bool get isCameraAvailable {
    if (kIsWeb) return false;
    return _isCameraSupportedPlatform;
  }

  /// Check if gallery is available
  bool get isGalleryAvailable => _isCameraSupportedPlatform;

  /// Pick image from camera
  Future<XFile?> capturePhoto() async {
    if (!isCameraAvailable) {
      debugPrint('Camera not available on this platform');
      return null;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickFromGallery() async {
    if (!isGalleryAvailable) {
      debugPrint('Gallery not available on this platform');
      return null;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages() async {
    if (!isGalleryAvailable) {
      debugPrint('Gallery not available on this platform');
      return [];
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload image to Supabase Storage
  /// Returns the public URL
  Future<String?> uploadAnimalPhoto({
    required String farmId,
    required String animalId,
    required XFile image,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final String path = 'farms/$farmId/animals/$animalId/photos/$fileName';

      // Read file bytes
      final Uint8List bytes = await image.readAsBytes();

      // Note: Supabase doesn't have built-in progress tracking for uploads
      // Report start and completion
      onProgress?.call(0.1);

      // Upload to Supabase Storage
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      onProgress?.call(1.0);

      // Get public URL
      final String publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  /// Upload profile photo (main animal photo)
  Future<String?> uploadProfilePhoto({
    required String farmId,
    required String animalId,
    required XFile image,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final String path = 'farms/$farmId/animals/$animalId/profile.jpg';

      // Read file bytes
      final Uint8List bytes = await image.readAsBytes();
      debugPrint('Uploading profile photo: $path (${bytes.length} bytes)');

      // Report start
      onProgress?.call(0.1);

      // Upload to Supabase Storage (upsert to replace existing)
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      onProgress?.call(1.0);
      debugPrint('Photo uploaded successfully to: $path');

      // Get public URL with cache-busting timestamp
      final String publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(path);
      debugPrint('Public URL: $publicUrl');
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      debugPrint('Storage error uploading profile photo: ${e.message}');
      debugPrint('Storage error code: ${e.statusCode}');
      debugPrint('Storage error details: ${e.error}');
      return null;
    } catch (e, stack) {
      debugPrint('Error uploading profile photo: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }

  /// Delete a photo from Supabase Storage
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      // Extract path from URL
      // URL format: https://[project].supabase.co/storage/v1/object/public/[bucket]/[path]
      final Uri uri = Uri.parse(photoUrl.split('?').first);
      final List<String> pathSegments = uri.pathSegments;

      // Find the index after 'public' and bucket name
      final int bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        debugPrint('Invalid photo URL format');
        return false;
      }

      final String path = pathSegments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from(_bucketName).remove([path]);
      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }

  /// Delete all photos for an animal
  Future<bool> deleteAllAnimalPhotos({
    required String farmId,
    required String animalId,
  }) async {
    try {
      final String path = 'farms/$farmId/animals/$animalId';

      // List all files in the photos folder
      final photosPath = '$path/photos';
      final List<FileObject> photoFiles = await _client.storage
          .from(_bucketName)
          .list(path: photosPath);

      // Delete all photo files
      if (photoFiles.isNotEmpty) {
        final filePaths = photoFiles
            .map((f) => '$photosPath/${f.name}')
            .toList();
        await _client.storage.from(_bucketName).remove(filePaths);
      }

      // Delete profile photo
      try {
        await _client.storage.from(_bucketName).remove(['$path/profile.jpg']);
      } catch (e) {
        // Profile photo might not exist, ignore error
        debugPrint('Profile photo not found or already deleted');
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting all photos: $e');
      return false;
    }
  }

  /// Get all photo URLs for an animal
  Future<List<String>> getAnimalPhotos({
    required String farmId,
    required String animalId,
  }) async {
    try {
      final String path = 'farms/$farmId/animals/$animalId/photos';

      final List<FileObject> files = await _client.storage
          .from(_bucketName)
          .list(path: path);

      final List<String> urls = [];
      for (final FileObject file in files) {
        final String url = _client.storage
            .from(_bucketName)
            .getPublicUrl('$path/${file.name}');
        urls.add(url);
      }

      return urls;
    } catch (e) {
      debugPrint('Error getting photos: $e');
      return [];
    }
  }
}
