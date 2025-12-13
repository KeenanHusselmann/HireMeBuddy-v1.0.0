import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderDocumentsReviewScreen extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDocumentsReviewScreen({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<ProviderDocumentsReviewScreen> createState() =>
      _ProviderDocumentsReviewScreenState();
}

class _ProviderDocumentsReviewScreenState
    extends ConsumerState<ProviderDocumentsReviewScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _providerData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Fetch provider profile with documents
      final profileData = await supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            first_name,
            last_name,
            email,
            phone,
            created_at,
            provider_profiles!provider_profiles_id_fkey (
              bio,
              is_verified,
              is_available,
              hourly_rate,
              documents_status,
              id_front_url,
              id_back_url,
              headshot_url,
              service_photos_urls,
              verification_notes
            )
          ''')
          .eq('id', widget.providerId)
          .single();

      setState(() {
        _providerData = profileData;
        final providerProfile = profileData['provider_profiles'] as Map<String, dynamic>?;
        _notesController.text = providerProfile?['verification_notes'] as String? ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDocumentStatus(String status) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
      }
      return;
    }

    try {
      await supabase.from('provider_profiles').update({
        'documents_status': status,
        'documents_reviewed_at': DateTime.now().toIso8601String(),
        'documents_reviewed_by': currentUser.id,
        'verification_notes': _notesController.text.trim(),
        // Also update verification status based on document approval
        'is_verified': status == 'approved',
      }).eq('id', widget.providerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documents ${status == 'approved' ? 'approved' : 'rejected'}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Documents'),
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Documents'),
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProviderData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final providerProfile = _providerData?['provider_profiles'] as Map<String, dynamic>?;
    if (providerProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Documents'),
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Provider profile not found'),
        ),
      );
    }

    final documentsStatus = providerProfile['documents_status'] as String? ?? 'pending';
    final idFrontUrl = providerProfile['id_front_url'] as String?;
    final idBackUrl = providerProfile['id_back_url'] as String?;
    final headshotUrl = providerProfile['headshot_url'] as String?;
    final servicePhotosUrls = (providerProfile['service_photos_urls'] as List?)?.cast<String>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Documents'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _providerData?['full_name'] as String? ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _providerData?['email'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _providerData?['phone'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: documentsStatus == 'approved'
                          ? Colors.green
                          : documentsStatus == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      documentsStatus.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show message if no documents uploaded
                  if (idFrontUrl == null && idBackUrl == null && headshotUrl == null && 
                      (servicePhotosUrls == null || servicePhotosUrls.isEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No Documents Uploaded',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This provider has not uploaded any verification documents yet. '
                                  'Documents will appear here once the provider completes the upload process.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ID Front
                  if (idFrontUrl != null) ...[
                    const Text(
                      'ID Document - Front',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageCard(idFrontUrl),
                    const SizedBox(height: 24),
                  ],

                  // ID Back
                  if (idBackUrl != null) ...[
                    const Text(
                      'ID Document - Back',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageCard(idBackUrl),
                    const SizedBox(height: 24),
                  ],

                  // Headshot
                  if (headshotUrl != null) ...[
                    const Text(
                      'Headshot Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageCard(headshotUrl),
                    const SizedBox(height: 24),
                  ],

                  // Service Photos
                  if (servicePhotosUrls != null && servicePhotosUrls.isNotEmpty) ...[
                    const Text(
                      'Service Portfolio Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...servicePhotosUrls.map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildImageCard(url),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Verification Notes
                  const Text(
                    'Verification Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add notes about verification...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateDocumentStatus('rejected'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateDocumentStatus('approved'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Show full-screen image
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: const Text('View Document'),
                ),
                backgroundColor: Colors.black,
                body: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tap to view full size',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.zoom_in,
                          size: 16,
                          color: Colors.deepOrange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expand image',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepOrange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
