import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/provider_info.dart';
import '../providers/admin_settings_provider.dart';
import 'provider_detail_screen.dart';

final providersListProvider = FutureProvider<List<ProviderInfo>>((ref) async {
  final adminService = AdminService();
  return await adminService.getAllProviders();
});

class ProvidersManagementScreen extends ConsumerWidget {
  const ProvidersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(providersListProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(providersListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(
            child: Text('No providers found'),
          );
        }

        final isTableView = ref.watch(tableViewEnabledProvider);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(providersListProvider),
          child: isTableView ? _buildTableView(providers, context, ref) : _buildCardView(providers, context, ref),
        );
      },
    );
  }

  Widget _buildTableView(List<ProviderInfo> providers, BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFF2C3E50).withOpacity(0.1),
          ),
          columns: const [
            DataColumn(label: Text('Provider', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Verified', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: providers.map((provider) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF7E57C2).withOpacity(0.1),
                        child: const Icon(
                          Icons.business,
                          color: Color(0xFF7E57C2),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(provider.businessName),
                    ],
                  ),
                ),
                DataCell(Text(provider.ownerName ?? 'N/A')),
                DataCell(Text(provider.email ?? 'N/A')),
                DataCell(Text('N\$${provider.hourlyRate.toStringAsFixed(2)}/hr')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.isAvailable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      provider.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: provider.isAvailable ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Icon(
                    provider.isVerified ? Icons.verified : Icons.pending,
                    color: provider.isVerified ? Colors.blue : Colors.orange,
                    size: 20,
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailScreen(
                                provider: provider,
                              ),
                            ),
                          );
                          if (result == true) {
                            ref.invalidate(providersListProvider);
                          }
                        },
                        tooltip: 'View Details',
                      ),
                      Switch(
                        value: provider.isAvailable,
                        onChanged: (value) async {
                          final adminService = AdminService();
                          await adminService.toggleProviderStatus(provider.id, value);
                          ref.invalidate(providersListProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardView(List<ProviderInfo> providers, BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderDetailScreen(
                    provider: provider,
                  ),
                ),
              );
              if (result == true) {
                ref.invalidate(providersListProvider);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF7E57C2).withOpacity(0.1),
                child: const Icon(
                  Icons.business,
                  color: Color(0xFF7E57C2),
                ),
              ),
              title: Text(provider.businessName),
              subtitle: Text(provider.ownerName ?? 'Unknown Owner'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isVerified)
                    const Icon(Icons.verified, color: Colors.blue, size: 20)
                  else
                    const Icon(Icons.pending, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Switch(
                    value: provider.isAvailable,
                    onChanged: (value) async {
                      final adminService = AdminService();
                      await adminService.toggleProviderStatus(provider.id, value);
                      ref.invalidate(providersListProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
