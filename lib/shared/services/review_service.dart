import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../models/review.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;

  // Create a new review
  Future<Review> createReview({
    required String bookingId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get client profile ID (user.id IS the profile id)
      final clientId = user.id;

      // Upsert review (insert or update if exists based on booking_id unique constraint)
      final response = await _supabase
          .from('reviews')
          .upsert(
            {
              'booking_id': bookingId,
              'reviewed_id': providerId,
              'reviewer_id': clientId,
              'rating': rating,
              'comment': comment,
            },
            onConflict: 'booking_id',
          )
          .select()
          .single();

      logger.info('ReviewService: Review created/updated successfully');
      return Review.fromJson(response);
    } catch (e) {
      logger.error('ReviewService: Error creating review', e);
      rethrow;
    }
  }

  // Get reviews for a provider
  Future<List<Review>> getProviderReviews(String providerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewed_id', providerId)
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
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            client:reviewer_id (
              full_name,
              avatar_url
            )
          ''')
          .eq('reviewed_id', providerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logger.error('ReviewService: Error fetching reviews with client details', e);
      rethrow;
    }
  }
}
