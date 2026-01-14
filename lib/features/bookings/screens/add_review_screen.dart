import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/review_service.dart';
import 'my_bookings_screen.dart' show bookingPaymentStatusProvider, clientBookingsProvider, reviewStatusProvider;

class AddReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;

  const AddReviewScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
  });

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reviewService.createReview(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
      );

      // Notify provider about new review
      try {
        final supabase = Supabase.instance.client;
        await supabase.rpc(
          'send_notification',
          params: {
            'p_user_id': widget.providerId,
            'p_title': 'New Review Received',
            'p_body': 'A client left you a new review.',
            'p_type': 'review',
          },
        );
      } catch (e) {
        // Log but don't block the review flow - silent fail
      }

      if (mounted) {
        // Invalidate payment status provider to refresh the "Pay Provider" button immediately
        ref.invalidate(bookingPaymentStatusProvider(widget.bookingId));
        ref.invalidate(clientBookingsProvider);
        ref.invalidate(reviewStatusProvider(widget.bookingId));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate review was added
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience with ${widget.providerName}?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Star Rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() => _rating = index + 1);
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingText(_rating),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Comment TextField
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Share your experience (optional)',
                hintText: 'Tell others about your experience...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Select Rating';
    }
  }
}
