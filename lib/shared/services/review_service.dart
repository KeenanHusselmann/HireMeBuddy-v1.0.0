import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../models/review.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;

  // Create a new review
  Future<Review> createReview({
    required String bookingId,
    required String providerId, // provider_profiles.id passed from booking object
    required int rating,
    String? comment,
  }) async {
    try {
      // Use simple submit_review function with clean table (no FK constraints)
      final response = await _supabase.rpc('submit_review', params: {
        'p_booking_id': bookingId,
        'p_provider_id': providerId,
        'p_rating': rating,
        'p_comment': comment,
      });

      logger.info('ReviewService: Review submitted successfully');
      return Review.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      logger.error('ReviewService: Error submitting review', e);
      rethrow;
    }
  }

  // Get reviews for a provider
  Future<List<Review>> getProviderReviews(String providerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      final reviews = (response as List)
          .map((review) => Review.fromJson(review))
          .toList();

      logger.info('ReviewService: Fetched ${reviews.length} reviews for provider');
      return reviews;
    } catch (e) {
      logger.error('ReviewService: Error fetching provider reviews', e);
      rethrow;
    }
  }

  // Get review for a specific booking
  Future<Review?> getReviewByBookingId(String bookingId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      
      return Review.fromJson(response);
    } catch (e) {
      logger.error('ReviewService: Error fetching review', e);
      rethrow;
    }
  }

  // Update a review
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .select()
          .single();

      logger.info('ReviewService: Review updated successfully');
      return Review.fromJson(response);
    } catch (e) {
      logger.error('ReviewService: Error updating review', e);
      rethrow;
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId);

      logger.info('ReviewService: Review deleted successfully');
    } catch (e) {
      logger.error('ReviewService: Error deleting review', e);
      rethrow;
    }
  }

  // Get reviews with client details
  Future<List<Map<String, dynamic>>> getProviderReviewsWithClientDetails(String providerId) async {
    try {
      final response = await _supabase.rpc('get_provider_reviews', params: {
        'p_provider_id': providerId,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logger.error('ReviewService: Error fetching reviews with client details', e);
      rethrow;
    }
  }
}
