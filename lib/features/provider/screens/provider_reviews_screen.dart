import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/review_service.dart';

class ProviderReviewsScreen extends ConsumerStatefulWidget {
  const ProviderReviewsScreen({super.key});

  @override
  ConsumerState<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends ConsumerState<ProviderReviewsScreen> {
  String? _providerId;
  bool _isLoading = true;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadProviderId();
  }

  void _refreshReviews() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _loadProviderId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      setState(() {
        _providerId = response['id'] as String;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading provider ID: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepOrange.shade600,
          foregroundColor: Colors.white,
          title: const Text('My Reviews'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    if (_providerId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepOrange.shade600,
          foregroundColor: Colors.white,
          title: const Text('My Reviews'),
        ),
        body: const Center(
          child: Text('Unable to load provider profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade600,
        foregroundColor: Colors.white,
        title: const Text('My Reviews'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReviews,
            tooltip: 'Refresh reviews',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: _getReviewsWithStats(_providerId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reviews',
                    style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final reviews = data['reviews'] as List<Map<String, dynamic>>;
          final avgRating = data['avgRating'] as double;
          final totalReviews = reviews.length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: Column(
              children: [
                // Stats Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < avgRating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getMotivationalMessage(avgRating, totalReviews),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Reviews List
                Expanded(
                  child: reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No reviews yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Complete jobs to receive reviews from clients',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            // Handle both old nested format and new flat format
                            final client = review['client'] as Map<String, dynamic>?;
                            final clientName = client?['full_name'] as String? ?? 
                                              review['client_full_name'] as String? ?? 
                                              'Anonymous';
                            final clientAvatar = client?['avatar_url'] as String? ?? 
                                                review['client_avatar_url'] as String?;
                            final rating = review['rating'] as int;
                            final comment = review['comment'] as String?;
                            final createdAt = DateTime.parse(review['created_at'] as String);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Client info
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.deepOrange.shade100,
                                          backgroundImage: clientAvatar != null
                                              ? NetworkImage(clientAvatar)
                                              : null,
                                          child: clientAvatar == null
                                              ? Text(
                                                  clientName.substring(0, 1).toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.deepOrange.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                clientName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('MMM d, yyyy').format(createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Rating stars
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < rating ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    // Comment
                                    if (comment != null && comment.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        comment,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getReviewsWithStats(String providerId) async {
    try {
      final reviews = await ReviewService().getProviderReviewsWithClientDetails(providerId);
      
      final avgRating = reviews.isEmpty 
          ? 0.0 
          : reviews.map((r) => r['rating'] as int).reduce((a, b) => a + b) / reviews.length;
      
      return {
        'reviews': reviews,
        'avgRating': avgRating,
      };
    } catch (e) {
      rethrow;
    }
  }

  String _getMotivationalMessage(double avgRating, int totalReviews) {
    if (totalReviews == 0) {
      return 'Complete your first job to receive reviews!';
    } else if (avgRating >= 4.5) {
      return '🌟 Outstanding! You\'re providing excellent service!';
    } else if (avgRating >= 4.0) {
      return '👍 Great work! Keep maintaining your quality service!';
    } else if (avgRating >= 3.5) {
      return '💪 Good job! A little improvement will make you shine!';
    } else if (avgRating >= 3.0) {
      return '📈 You\'re doing well! Focus on exceeding client expectations!';
    } else {
      return '🎯 Every job is a chance to improve and grow!';
    }
  }
}
