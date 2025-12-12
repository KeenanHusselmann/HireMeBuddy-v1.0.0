import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/provider_info.dart';
import '../services/admin_service.dart';

class ProviderDetailScreen extends ConsumerWidget {
  final ProviderInfo provider;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
  });

  Future<void> _handleVerification(
    BuildContext context,
    WidgetRef ref,
    bool isVerified,
  ) async {
    final adminService = AdminService();
    try {
      await adminService.verifyProvider(provider.id, isVerified);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVerified
                  ? 'Provider verified successfully!'
                  : 'Provider verification removed',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Details'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          if (provider.isVerified)
            IconButton(
              icon: const Icon(Icons.verified, color: Colors.blue),
              onPressed: () {},
              tooltip: 'Verified Provider',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF7E57C2).withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: const Color(0xFF7E57C2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.ownerName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: provider.isVerified
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: provider.isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.isVerified
                              ? Icons.verified
                              : Icons.pending,
                          size: 18,
                          color: provider.isVerified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isVerified ? 'VERIFIED' : 'PENDING VERIFICATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: provider.isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Contact Information
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow(Icons.email, 'Email', provider.email ?? 'Not provided'),
              _buildInfoRow(Icons.phone, 'Phone', provider.phone ?? 'Not provided'),
            ]),

            const SizedBox(height: 24),

            // Professional Details
            _buildSectionTitle('Professional Details'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow(
                Icons.attach_money,
                'Hourly Rate',
                'N\$${provider.hourlyRate.toStringAsFixed(2)}/hr',
              ),
              _buildInfoRow(
                Icons.toggle_on,
                'Availability',
                provider.isAvailable ? 'Available' : 'Not Available',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Joined',
                DateFormat('MMMM d, yyyy').format(provider.createdAt),
              ),
            ]),

            const SizedBox(height: 24),

            // Bio
            if (provider.bio != null && provider.bio!.isNotEmpty) ...[
              _buildSectionTitle('About'),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    provider.bio!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Verification Actions
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            _buildSectionTitle('Verification Actions'),
            const SizedBox(height: 16),

            if (!provider.isVerified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleVerification(context, ref, true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve & Verify Provider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleVerification(context, ref, false),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Revoke Verification'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
