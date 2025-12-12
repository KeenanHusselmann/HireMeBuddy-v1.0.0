import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PortfolioService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Pick video from gallery
  Future<XFile?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      throw Exception('Failed to pick video: $e');
    }
  }

  // Record video with camera
  Future<XFile?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      throw Exception('Failed to record video: $e');
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Take photo with camera
  Future<XFile?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return photo;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Upload image to Supabase Storage
  Future<String> uploadPortfolioImage({
    required String providerId,
    required String filePath,
    String mediaType = 'photo',
  }) async {
    try {
      final file = File(filePath);
      final fileExt = filePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$providerId/$fileName';

      await _supabase.storage
          .from('portfolio-images')
          .upload(storagePath, file);

      final publicUrl = _supabase.storage
          .from('portfolio-images')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Add portfolio image to database
  Future<void> addPortfolioImage({
    required String providerId,
    required String imageUrl,
    String? description,
    String mediaType = 'photo',
  }) async {
    try {
      // Get current count to determine display order
      final existing = await _supabase
          .from('portfolio_images')
          .select('id')
          .eq('provider_id', providerId)
          .eq('media_type', mediaType);
      
      final nextOrder = (existing as List).length + 1;
      
      await _supabase.from('portfolio_images').insert({
        'provider_id': providerId,
        'image_url': imageUrl,
        'description': description,
        'media_type': mediaType,
        'display_order': nextOrder,
      });
    } catch (e) {
      throw Exception('Failed to add portfolio image: $e');
    }
  }

  // Get provider's portfolio images by type
  Future<List<Map<String, dynamic>>> getPortfolioImagesByType(
    String providerId,
    String mediaType,
  ) async {
    try {
      final response = await _supabase
          .from('portfolio_images')
          .select()
          .eq('provider_id', providerId)
          .eq('media_type', mediaType)
          .order('display_order', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get portfolio images: $e');
    }
  }

  // Get provider's portfolio images
  Future<List<Map<String, dynamic>>> getPortfolioImages(String providerId) async {
    try {
      final response = await _supabase
          .from('portfolio_images')
          .select()
          .eq('provider_id', providerId)
          .order('display_order', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get portfolio images: $e');
    }
  }

  // Delete portfolio image
  Future<void> deletePortfolioImage({
    required String imageId,
    required String imageUrl,
  }) async {
    try {
      // Extract storage path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('portfolio-images');
      
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        // Delete from storage
        await _supabase.storage
            .from('portfolio-images')
            .remove([storagePath]);
      }

      // Delete from database
      await _supabase
          .from('portfolio_images')
          .delete()
          .eq('id', imageId);
    } catch (e) {
      throw Exception('Failed to delete portfolio image: $e');
    }
  }

  // Update portfolio image description
  Future<void> updatePortfolioImageDescription({
    required String imageId,
    required String description,
  }) async {
    try {
      await _supabase
          .from('portfolio_images')
          .update({'description': description})
          .eq('id', imageId);
    } catch (e) {
      throw Exception('Failed to update description: $e');
    }
  }

  // Add testimonial
  Future<void> addTestimonial({
    required String providerId,
    required String clientName,
    String? clientAvatar,
    required int rating,
    required String comment,
    String? projectTitle,
    bool isFeatured = false,
  }) async {
    try {
      final existing = await _supabase
          .from('testimonials')
          .select('id')
          .eq('provider_id', providerId);
      
      final nextOrder = (existing as List).length + 1;

      await _supabase.from('testimonials').insert({
        'provider_id': providerId,
        'client_name': clientName,
        'client_avatar': clientAvatar,
        'rating': rating,
        'comment': comment,
        'project_title': projectTitle,
        'is_featured': isFeatured,
        'display_order': nextOrder,
      });
    } catch (e) {
      throw Exception('Failed to add testimonial: $e');
    }
  }

  // Get provider's testimonials
  Future<List<Map<String, dynamic>>> getTestimonials(String providerId) async {
    try {
      final response = await _supabase
          .from('testimonials')
          .select()
          .eq('provider_id', providerId)
          .order('display_order', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get testimonials: $e');
    }
  }

  // Delete testimonial
  Future<void> deleteTestimonial(String testimonialId) async {
    try {
      await _supabase
          .from('testimonials')
          .delete()
          .eq('id', testimonialId);
    } catch (e) {
      throw Exception('Failed to delete testimonial: $e');
    }
  }
}
