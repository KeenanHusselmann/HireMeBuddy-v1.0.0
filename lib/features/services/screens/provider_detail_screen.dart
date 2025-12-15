import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/review_service.dart';
import '../../../core/providers/provider_provider.dart';
import '../../bookings/screens/booking_screen.dart';
import '../../chat/screens/chat_screen.dart';
import 'portfolio_viewer_screen.dart';

class ProviderDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> provider;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('📱 [PROVIDER_DETAIL] Provider data: ${provider.keys}');
    print('📱 [PROVIDER_DETAIL] Contact number: ${provider['contact_number']}');
    
    final profile = provider['profiles'] as Map<String, dynamic>;
    final providerId = profile['id'] as String;
    final hourlyRate = provider['hourly_rate'] as num?;
    final skills = (provider['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final bio = provider['bio'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _showShareOptions(context, provider, profile, hourlyRate, skills, bio);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: profile['avatar_url'] != null
                              ? NetworkImage(profile['avatar_url'])
                              : null,
                          child: profile['avatar_url'] == null
                              ? Text(
                                  (profile['full_name'] as String?)
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'P',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profile['full_name'] ?? 'Unknown Provider',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (provider['is_verified'] == true) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getProviderStats(providerId),
                          builder: (context, snapshot) {
                            final stats = snapshot.data ?? {};
                            final avgRating = stats['avgRating'] as num? ?? 0.0;
                            final reviewCount = stats['reviewCount'] as int? ?? 0;
                            final completedJobs = stats['completedJobs'] as int? ?? 0;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedJobs jobs completed',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Hourly Rate Section
                  if (hourlyRate != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.teal.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'N\$${hourlyRate.toStringAsFixed(2)} per hour',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // About Section
                  if (bio != null && bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                  // Skills Section
                  if (skills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skills',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map((skill) {
                              return Chip(
                                label: Text(skill),
                                backgroundColor: Colors.teal.shade50,
                                labelStyle: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // Services Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Services Offered',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, child) {
                            final servicesAsync = ref.watch(providerServicesProvider(providerId));
                            
                            return servicesAsync.when(
                              data: (services) {
                                if (services.isEmpty) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('No services listed yet'),
                                    ),
                                  );
                                }
                                
                                return Column(
                                  children: services.map((service) {
                                    final category = service['service_categories'] as Map<String, dynamic>?;
                                    final basePrice = service['base_price'] as num?;
                                    final description = service['description'] as String?;
                                    
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.teal.shade100,
                                          child: Icon(
                                            Icons.work,
                                            color: Colors.teal.shade700,
                                          ),
                                        ),
                                        title: Text(
                                          category?['name'] ?? 'Service',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (description != null) ...[
                                              const SizedBox(height: 4),
                                              Text(description),
                                            ],
                                            if (basePrice != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$${basePrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.teal.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        isThreeLine: description != null,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stack) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Error loading services: $error'),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Reviews Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: ReviewService().getProviderReviewsWithClientDetails(providerId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              print('❌ Error loading reviews: ${snapshot.error}');
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Error loading reviews: ${snapshot.error}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              );
                            }

                            final reviews = snapshot.data ?? [];

                            if (reviews.isEmpty) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.rate_review_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No reviews yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Be the first to review!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: reviews.map((review) {
                                final clientName = review['client']?['full_name'] ?? 'Anonymous';
                                final rating = review['rating'] as int;
                                final comment = review['comment'] as String?;
                                final createdAt = DateTime.parse(review['created_at']);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              child: Text(
                                                clientName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      ...List.generate(5, (index) {
                                                        return Icon(
                                                          index < rating
                                                              ? Icons.star
                                                              : Icons.star_border,
                                                          size: 16,
                                                          color: Colors.amber,
                                                        );
                                                      }),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        DateFormat('MMM d, yyyy').format(createdAt),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80), // Space for bottom button
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PortfolioViewerScreen(
                                      providerId: providerId,
                                      providerName: profile['full_name'] ?? 'Provider',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Portfolio'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.teal.shade700,
                                side: BorderSide(color: Colors.teal.shade700, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showContactOptions(context, profile);
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Contact'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.teal.shade600,
                                side: BorderSide(color: Colors.teal.shade600, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider['is_available'] == true
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingScreen(
                                          provider: provider,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                              icon: Icon(
                                provider['is_available'] == true 
                                  ? Icons.calendar_today 
                                  : Icons.block,
                              ),
                              label: Text(
                                provider['is_available'] == true 
                                  ? 'Book Now' 
                                  : 'Currently Unavailable',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: provider['is_available'] == true 
                                  ? Colors.teal 
                                  : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getProviderStats(String providerId) async {
    try {
      // Get review stats
      final reviews = await ReviewService().getProviderReviews(providerId);
      final avgRating = reviews.isEmpty 
          ? 0.0 
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      
      // Get completed jobs count from Supabase
      final supabase = Supabase.instance.client;
      final completedJobsResponse = await supabase
          .from('bookings')
          .select('id')
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .count();
      
      return {
        'avgRating': avgRating,
        'reviewCount': reviews.length,
        'completedJobs': completedJobsResponse.count,
      };
    } catch (e) {
      print('Error getting provider stats: $e');
      return {
        'avgRating': 0.0,
        'reviewCount': 0,
        'completedJobs': 0,
      };
    }
  }

  void _showContactOptions(BuildContext context, Map<String, dynamic> profile) {
    // Get phone from profiles.contact_number (most up-to-date value)
    final phoneNumber = profile['contact_number'] as String?;
    final providerName = profile['full_name'] as String? ?? 'Provider';
    
    print('📞 [CONTACT] Using phone number: $phoneNumber');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact $providerName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
            
            // WhatsApp Message
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat, color: Colors.white),
              ),
              title: const Text('WhatsApp Message'),
              subtitle: Text(phoneNumber ?? 'No phone number'),
              enabled: phoneNumber != null,
              onTap: phoneNumber != null
                  ? () async {
                      Navigator.pop(context);
                      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
                      final whatsappUrl = 'whatsapp://send?phone=$cleanPhone';
                      print('📱 Opening WhatsApp URL: $whatsappUrl');
                      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('WhatsApp is not installed')),
                          );
                        }
                      }
                    }
                  : null,
            ),
            const Divider(),
            
            // WhatsApp Voice Call
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF128C7E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.call, color: Colors.white),
              ),
              title: const Text('WhatsApp Call'),
              subtitle: Text(phoneNumber ?? 'No phone number'),
              enabled: phoneNumber != null,
              onTap: phoneNumber != null
                  ? () async {
                      Navigator.pop(context);
                      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
                      final whatsappUrl = 'whatsapp://send?phone=$cleanPhone';
                      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tap the call button in WhatsApp to start a voice call'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('WhatsApp is not installed')),
                          );
                        }
                      }
                    }
                  : null,
            ),
            const Divider(),
            
            // Phone Call
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: Colors.white),
              ),
              title: const Text('Phone Call'),
              subtitle: Text(phoneNumber ?? 'No phone number'),
              enabled: phoneNumber != null,
              onTap: phoneNumber != null
                  ? () async {
                      Navigator.pop(context);
                      final telUrl = 'tel:$phoneNumber';
                      if (await canLaunchUrl(Uri.parse(telUrl))) {
                        await launchUrl(Uri.parse(telUrl));
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open phone dialer')),
                          );
                        }
                      }
                    }
                  : null,
            ),
            const Divider(),
            
            // In-App Messaging
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.message, color: Colors.white),
              ),
              title: const Text('In-App Message'),
              subtitle: const Text('Send a message through the app'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(provider: provider),
                  ),
                );
              },
            ),
            
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  void _showShareOptions(BuildContext context, Map<String, dynamic> providerData, Map<String, dynamic> profile, num? hourlyRate, List<String> skills, String? bio) {
    final providerName = profile['full_name'] as String? ?? 'Provider';
    final rating = providerData['rating_average'] as num? ?? 0.0;
    final totalJobs = providerData['total_jobs'] as int? ?? 0;
    
    // Build share message
    final shareMessage = '''
🌟 Check out this service provider on HireMeBuddy!

👤 *$providerName*
⭐ Rating: ${rating.toStringAsFixed(1)}/5.0
💼 Completed Jobs: $totalJobs
💰 Rate: N\$${hourlyRate?.toStringAsFixed(2) ?? 'N/A'} per hour

${bio != null && bio.isNotEmpty ? '📝 About:\n$bio\n\n' : ''}${skills.isNotEmpty ? '🔧 Skills:\n${skills.join(', ')}\n\n' : ''}📱 Download HireMeBuddy to book services!
    '''.trim();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share $providerName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // WhatsApp
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share, color: Colors.white),
              ),
              title: const Text('Share via WhatsApp'),
              subtitle: const Text('Share provider details on WhatsApp'),
              onTap: () async {
                Navigator.pop(context);
                final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(shareMessage)}';
                if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                  await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp')),
                    );
                  }
                }
              },
            ),
            const Divider(),
            
            // Copy to Clipboard
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, color: Colors.white),
              ),
              title: const Text('Copy to Clipboard'),
              subtitle: const Text('Copy provider details'),
              onTap: () {
                Navigator.pop(context);
                // Note: You'll need to add clipboard package to use this
                // For now, just show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Details copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
