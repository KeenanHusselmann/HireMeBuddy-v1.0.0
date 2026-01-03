import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/services/portfolio_service.dart';
import '../../../shared/widgets/video_player_widget.dart';

class PortfolioViewerScreen extends ConsumerStatefulWidget {
  final String providerId;
  final String providerName;

  const PortfolioViewerScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  ConsumerState<PortfolioViewerScreen> createState() => _PortfolioViewerScreenState();
}

class _PortfolioViewerScreenState extends ConsumerState<PortfolioViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.providerName}\'s Portfolio'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.rate_review), text: 'Testimonials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotosTab(),
          _buildVideosTab(),
          _buildTestimonialsTab(),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    return _buildMediaGrid('photo');
  }

  Widget _buildVideosTab() {
    return _buildMediaGrid('video');
  }

  Widget _buildMediaGrid(String mediaType) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PortfolioService().getPortfolioImagesByType(widget.providerId, mediaType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
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
                  'No ${mediaType}s available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isVideo = mediaType == 'video';
            
            return GestureDetector(
              onTap: () => _showFullImage(item, isVideo),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isVideo
                        ? FutureBuilder<String?>(
                            future: _generateThumbnail(item['image_url']),
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
                                            size: 40,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Video',
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
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
                                      size: 40,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Video',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.network(
                            item['image_url'],
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
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTestimonialsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PortfolioService().getTestimonials(widget.providerId),
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
                  'No testimonials available',
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
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue,
                          child: Text(
                            testimonial['client_name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testimonial['client_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < testimonial['rating']
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (testimonial['project_title'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          testimonial['project_title'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      testimonial['comment'],
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  void _showFullImage(Map<String, dynamic> item, bool isVideo) {
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
                child: VideoPlayerWidget(videoUrl: item['image_url']),
              )
            else
              Image.network(
                item['image_url'],
                fit: BoxFit.contain,
              ),
            if (item['description'] != null && item['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(item['description']),
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
}
