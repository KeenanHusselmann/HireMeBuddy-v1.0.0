import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
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
                '1. Acceptance of Terms',
                'By accessing and using HireMeBuddy, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, please do not use our service.',
              ),

              _buildSection(
                context,
                '2. Service Provider Agreement',
                'By registering as a service provider on HireMeBuddy, you agree to:\n\n'
                '• Provide professional services to clients through our platform\n'
                '• Maintain accurate and up-to-date profile information\n'
                '• Respond to client inquiries in a timely manner\n'
                '• Complete all accepted bookings to the best of your ability\n'
                '• Comply with all applicable laws and regulations',
              ),

              _buildSection(
                context,
                '3. User Responsibilities',
                'You are responsible for:\n\n'
                '• Maintaining the confidentiality of your account credentials\n'
                '• All activities that occur under your account\n'
                '• Ensuring all information provided is accurate and truthful\n'
                '• Using the platform in accordance with these terms',
              ),

              _buildSection(
                context,
                '4. Professional Conduct',
                'Service providers agree to:\n\n'
                '• Maintain professional standards in all interactions\n'
                '• Deliver quality services as described in their profile\n'
                '• Treat all clients with respect and courtesy\n'
                '• Adhere to agreed-upon schedules and commitments\n'
                '• Resolve disputes in a professional manner',
              ),

              _buildSection(
                context,
                '5. Verification Process',
                'All service providers must undergo verification:\n\n'
                '• Valid government-issued ID must be provided\n'
                '• Profile information will be reviewed by our team\n'
                '• Service photos must be authentic and representative\n'
                '• We reserve the right to reject applications that don\'t meet our standards\n'
                '• Verification typically takes 1-3 business days',
              ),

              _buildSection(
                context,
                '6. Payment Terms',
                '• Platform fees apply to all transactions\n'
                '• Payments are processed securely through our payment provider\n'
                '• Service providers receive payment according to our payment schedule\n'
                '• Cancellation and refund policies apply as per platform rules\n'
                '• All prices are in Namibian Dollars (NAD)',
              ),

              _buildSection(
                context,
                '7. Cancellation Policy',
                '• Bookings can be cancelled according to the provider\'s cancellation policy\n'
                '• Late cancellations may result in fees\n'
                '• Providers who repeatedly cancel bookings may face account restrictions\n'
                '• Emergency cancellations will be reviewed on a case-by-case basis',
              ),

              _buildSection(
                context,
                '8. Ratings and Reviews',
                '• Clients can rate and review services\n'
                '• Reviews must be honest and based on actual experience\n'
                '• Fake or fraudulent reviews are prohibited\n'
                '• We reserve the right to remove inappropriate reviews\n'
                '• Providers can respond to reviews professionally',
              ),

              _buildSection(
                context,
                '9. Account Termination',
                'We reserve the right to suspend or terminate accounts that:\n\n'
                '• Violate these terms of service\n'
                '• Engage in fraudulent activity\n'
                '• Receive repeated complaints from clients\n'
                '• Provide false information during registration\n'
                '• Engage in inappropriate or unprofessional conduct',
              ),

              _buildSection(
                context,
                '10. Liability and Disclaimers',
                '• HireMeBuddy acts as a platform connecting clients and service providers\n'
                '• Service providers are independent contractors, not employees\n'
                '• Providers are responsible for their own actions and services\n'
                '• The platform is provided "as is" without warranties\n'
                '• We are not liable for disputes between clients and providers',
              ),

              _buildSection(
                context,
                '11. Intellectual Property',
                '• You retain ownership of content you upload\n'
                '• You grant us license to display your content on the platform\n'
                '• You must not upload copyrighted material without permission\n'
                '• Platform design and features are protected by copyright',
              ),

              _buildSection(
                context,
                '12. Dispute Resolution',
                '• Disputes should first be resolved through platform messaging\n'
                '• Escalated disputes will be reviewed by our support team\n'
                '• We may mediate disputes but are not obligated to do so\n'
                '• Legal action should be a last resort',
              ),

              _buildSection(
                context,
                '13. Changes to Terms',
                'We reserve the right to modify these terms at any time. Users will be notified of significant changes. Continued use of the platform after changes constitutes acceptance of the new terms.',
              ),

              _buildSection(
                context,
                '14. Contact Information',
                'For questions about these terms, please contact:\n\n'
                'Email: support@hiremebuddy.app\n'
                'Phone: +264 XX XXX XXXX\n'
                'Address: Windhoek, Namibia',
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
