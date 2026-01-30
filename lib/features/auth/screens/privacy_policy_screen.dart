import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: January 2026',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              _buildSection(
                context,
                '1. Introduction',
                'HireMeBuddy ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
              ),

              _buildSection(
                context,
                '2. Information We Collect',
                'We collect several types of information:\n\n'
                '• Personal Information: Name, email address, phone number, physical address\n'
                '• Identification Documents: Government-issued ID for verification purposes\n'
                '• Profile Information: Bio, skills, experience, service photos, headshot\n'
                '• Transaction Data: Booking details, payment information, ratings, and reviews\n'
                '• Location Data: Your location when using location-based features\n'
                '• Device Information: Device type, operating system, unique device identifiers\n'
                '• Usage Data: How you interact with the app, features used, time spent',
              ),

              _buildSection(
                context,
                '3. How We Use Your Information',
                'We use collected information to:\n\n'
                '• Verify your identity and approve service provider applications\n'
                '• Display your profile to potential clients\n'
                '• Facilitate bookings and transactions\n'
                '• Process payments securely\n'
                '• Send notifications about bookings, messages, and updates\n'
                '• Improve our services and user experience\n'
                '• Prevent fraud and ensure platform security\n'
                '• Comply with legal obligations\n'
                '• Provide customer support',
              ),

              _buildSection(
                context,
                '4. Data Storage and Security',
                'Your data is stored securely:\n\n'
                '• All data is encrypted in transit and at rest\n'
                '• We use industry-standard security measures\n'
                '• Access to personal data is restricted to authorized personnel\n'
                '• Regular security audits are conducted\n'
                '• Data is stored on secure servers with Supabase\n'
                '• Payment information is processed through secure payment gateways',
              ),

              _buildSection(
                context,
                '5. Data Sharing and Disclosure',
                'We do not sell your personal information. We may share data with:\n\n'
                '• Service Providers: Third-party services that help operate our platform (payment processors, cloud storage, analytics)\n'
                '• Clients: Your public profile information is visible to potential clients\n'
                '• Legal Authorities: When required by law or to protect our rights\n'
                '• Business Transfers: In case of merger, acquisition, or sale of assets',
              ),

              _buildSection(
                context,
                '6. Your Rights',
                'You have the right to:\n\n'
                '• Access your personal information\n'
                '• Correct inaccurate or incomplete data\n'
                '• Request deletion of your data\n'
                '• Object to processing of your data\n'
                '• Export your data in a portable format\n'
                '• Withdraw consent at any time\n'
                '• Lodge a complaint with data protection authorities',
              ),

              _buildSection(
                context,
                '7. Data Retention',
                '• Active account data is retained for as long as your account is active\n'
                '• After account deletion, some data may be retained for legal compliance\n'
                '• Transaction records are kept for accounting and tax purposes\n'
                '• Backup copies may exist for a limited time after deletion',
              ),

              _buildSection(
                context,
                '8. Cookies and Tracking',
                'We use cookies and similar technologies to:\n\n'
                '• Remember your preferences and settings\n'
                '• Analyze app usage and performance\n'
                '• Provide personalized content\n'
                '• Improve security\n\nYou can control cookies through your device settings.',
              ),

              _buildSection(
                context,
                '9. Location Information',
                '• We collect location data when you use location-based features\n'
                '• Location is used to show relevant service providers\n'
                '• You can control location permissions in your device settings\n'
                '• Precise location is not shared publicly unless you choose to',
              ),

              _buildSection(
                context,
                '10. Children\'s Privacy',
                'Our services are not intended for children under 18. We do not knowingly collect information from children. If you believe we have collected data from a child, please contact us immediately.',
              ),

              _buildSection(
                context,
                '11. Third-Party Links',
                'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.',
              ),

              _buildSection(
                context,
                '12. Push Notifications',
                '• We send push notifications about bookings, messages, and updates\n'
                '• You can disable notifications in your device settings\n'
                '• Some notifications may be essential for platform functionality',
              ),

              _buildSection(
                context,
                '13. International Data Transfers',
                'Your information may be transferred to and processed in countries other than Namibia. We ensure appropriate safeguards are in place for international transfers.',
              ),

              _buildSection(
                context,
                '14. Changes to Privacy Policy',
                'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or by email. Continued use after changes constitutes acceptance.',
              ),

              _buildSection(
                context,
                '15. Contact Us',
                'For privacy-related questions or to exercise your rights:\n\n'
                'Email: privacy@hiremebuddy.app\n'
                'Phone: +264 XX XXX XXXX\n'
                'Address: Windhoek, Namibia\n\n'
                'We will respond to your requests within 30 days.',
              ),

              const SizedBox(height: 40),

              Center(
                child: Text(
                  '© 2026 HireMeBuddy. All rights reserved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
