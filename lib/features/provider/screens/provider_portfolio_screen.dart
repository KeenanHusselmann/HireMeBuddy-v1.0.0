import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/video_player_widget.dart';

class ProviderPortfolioScreen extends ConsumerStatefulWidget {
  const ProviderPortfolioScreen({super.key});

  @override
  ConsumerState<ProviderPortfolioScreen> createState() => _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends ConsumerState<ProviderPortfolioScreen>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.rate_review), text: 'Testimonials'),
          ],
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotosTab(user.id),
          _buildVideosTab(user.id),
          _buildTestimonialsTab(user.id),
        ],
      ),
      floatingActionButton: _isUploading
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddDialog(user.id),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildPhotosTab(String userId) {
    return _buildMediaGrid(userId, 'photo');
  }

  Widget _buildVideosTab(String userId) {
    return _buildMediaGrid(userId, 'video');
  }

  Widget _buildMediaGrid(String userId, String mediaType) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('media_${mediaType}_$_refreshKey'),
      future: ref.read(portfolioServiceProvider).getPortfolioImagesByType(userId, mediaType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final images = snapshot.data ?? [];

        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mediaType == 'photo' ? Icons.photo_library : Icons.videocam,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${mediaType}s yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your work',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return _buildMediaCard(image, userId);
          },
        );
      },
    );
  }

  Widget _buildMediaCard(Map<String, dynamic> image, String userId) {
    final isVideo = image['media_type'] == 'video';
    
    return GestureDetector(
      onTap: () => _showImageDialog(image),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isVideo
                ? FutureBuilder<String?>(
                    future: _generateThumbnail(image['image_url']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.black87,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.black87,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 60,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Video',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                      
                      return Container(
                        color: Colors.black87,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 60,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Video',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Image.network(
                    image['image_url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
          ),
          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 50,
                color: Colors.white,
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.7),
              ),
              onPressed: () => _deleteImage(image['id'], image['image_url'], userId),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _generateThumbnail(String videoUrl) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  Widget _buildTestimonialsTab(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('testimonials_$_refreshKey'),
      future: ref.read(portfolioServiceProvider).getTestimonials(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final testimonials = snapshot.data ?? [];

        if (testimonials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No testimonials yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: testimonials.length,
          itemBuilder: (context, index) {
            final testimonial = testimonials[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(testimonial['client_name'][0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testimonial['client_name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < testimonial['rating']
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTestimonial(testimonial['id'], userId),
                        ),
                      ],
                    ),
                    if (testimonial['project_title'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        testimonial['project_title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(testimonial['comment']),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog(String userId) {
    final currentTab = _tabController.index;
    if (currentTab == 0 || currentTab == 1) {
      _showImageSourceDialog(currentTab == 1 ? 'video' : 'photo');
    } else {
      _showAddTestimonialDialog(userId);
    }
  }

  void _showAddTestimonialDialog(String userId) {
    final nameController = TextEditingController();
    final projectController = TextEditingController();
    final commentController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Testimonial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projectController,
                  decoration: const InputDecoration(
                    labelText: 'Project Title (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rating: '),
                    ...List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => rating = i + 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                Navigator.pop(context);
                try {
                  await ref.read(portfolioServiceProvider).addTestimonial(
                        providerId: userId,
                        clientName: nameController.text.trim(),
                        rating: rating,
                        comment: commentController.text.trim(),
                        projectTitle: projectController.text.trim().isEmpty
                            ? null
                            : projectController.text.trim(),
                      );
                  if (mounted) {
                    setState(() => _refreshKey++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Testimonial added!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(Map<String, dynamic> image) {
    final isVideo = image['media_type'] == 'video';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isVideo ? Colors.black : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVideo)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: VideoPlayerWidget(videoUrl: image['image_url']),
              )
            else
              Image.network(
                image['image_url'],
                fit: BoxFit.contain,
              ),
            if (image['description'] != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(image['description']),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(String mediaType) async {
    final isVideo = mediaType == 'video';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${isVideo ? 'Video' : 'Photo'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isVideo ? Icons.videocam : Icons.camera_alt),
              title: Text(isVideo ? 'Record Video' : 'Take Photo'),
              onTap: () {
                Navigator.pop(context);
                if (isVideo) {
                  _recordVideo(mediaType);
                } else {
                  _takePhoto(mediaType);
                }
              },
            ),
            ListTile(
              leading: Icon(isVideo ? Icons.video_library : Icons.photo_library),
              title: Text(isVideo ? 'Choose Video' : 'Choose Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(mediaType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(String mediaType) async {
    try {
      setState(() => _isUploading = true);
      
      final service = ref.read(portfolioServiceProvider);
      final photo = await service.takePhoto();
      
      if (photo == null) {
        setState(() => _isUploading = false);
        return;
      }

      await _uploadImage(photo.path, mediaType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _recordVideo(String mediaType) async {
    try {
      print('Starting video recording...');
      setState(() => _isUploading = true);
      
      final service = ref.read(portfolioServiceProvider);
      final video = await service.recordVideo();
      
      if (video == null) {
        print('Video recording cancelled');
        return;
      }

      print('Video path: ${video.path}');
      await _uploadImage(video.path, mediaType);
    } catch (e) {
      print('Record video error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        print('Resetting _isUploading to false');
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickFromGallery(String mediaType) async {
    try {
      print('Picking from gallery, mediaType: $mediaType');
      setState(() => _isUploading = true);
      
      final service = ref.read(portfolioServiceProvider);
      final XFile? media;
      
      if (mediaType == 'video') {
        print('Calling pickVideoFromGallery...');
        media = await service.pickVideoFromGallery();
      } else {
        print('Calling pickImageFromGallery...');
        media = await service.pickImageFromGallery();
      }
      
      if (media == null) {
        print('Media selection cancelled');
        return;
      }

      print('Media selected: ${media.path}');
      await _uploadImage(media.path, mediaType);
    } catch (e) {
      print('Pick from gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick ${mediaType == 'video' ? 'video' : 'image'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        print('Resetting _isUploading to false (pickFromGallery)');
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadImage(String filePath, String mediaType) async {
    print('Starting upload for $mediaType: $filePath');
    
    // Show uploading message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text('Uploading ${mediaType == 'video' ? 'video' : 'photo'}... Please wait'),
          ],
        ),
        duration: const Duration(minutes: 5), // Long duration for video uploads
        backgroundColor: Colors.blue,
      ),
    );
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not found');

      final service = ref.read(portfolioServiceProvider);
      
      print('Uploading to storage...');
      // Upload to storage
      final imageUrl = await service.uploadPortfolioImage(
        providerId: user.id,
        filePath: filePath,
        mediaType: mediaType,
      );

      print('Upload successful, URL: $imageUrl');
      print('Adding to database...');
      // Add to database
      await service.addPortfolioImage(
        providerId: user.id,
        imageUrl: imageUrl,
        mediaType: mediaType,
      );

      print('Database insert successful');
      // Refresh
      setState(() => _refreshKey++);

      if (mounted) {
        // Hide uploading message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${mediaType == 'video' ? 'Video' : 'Photo'} uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        // Hide uploading message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      rethrow; // Re-throw so the calling function can handle it
    }
  }

  Future<void> _deleteImage(String imageId, String imageUrl, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final service = ref.read(portfolioServiceProvider);
      await service.deletePortfolioImage(
        imageId: imageId,
        imageUrl: imageUrl,
      );

      setState(() => _refreshKey++);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTestimonial(String testimonialId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Testimonial'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(portfolioServiceProvider).deleteTestimonial(testimonialId);
      if (mounted) {
        setState(() => _refreshKey++);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
