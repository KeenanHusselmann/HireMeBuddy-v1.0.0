import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/utils/logger.dart';

// Provider for fetching random provider videos
final randomProviderVideosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Get random videos from portfolio with provider info
    final response = await supabase
        .from('portfolio_images')
        .select('''
          id,
          image_url,
          description,
          provider_id,
          provider_profiles!inner(
            id,
            hourly_rate,
            bio,
            profiles!inner(
              id,
              full_name,
              avatar_url
            )
          )
        ''')
        .eq('media_type', 'video')
        .limit(20);
    
    // Shuffle the results to show random videos
    final videos = (response as List).cast<Map<String, dynamic>>();
    videos.shuffle();
    
    return videos.take(10).toList();
  } catch (e) {
    logger.error('Error fetching random videos', e);
    return [];
  }
});

class ProviderVideoFeed extends ConsumerWidget {
  const ProviderVideoFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(randomProviderVideosProvider);

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.video_library, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Discover Providers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Refresh videos
                      ref.invalidate(randomProviderVideosProvider);
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 520,
              child: PageView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: VideoCard(video: video),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        logger.error('Error loading videos', error, stack);
        return const SizedBox.shrink();
      },
    );
  }
}

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;

  const VideoCard({super.key, required this.video});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video['image_url']),
      );
      
      await _controller.initialize();
      _controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      logger.error('Error initializing video', e);
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerProfile = widget.video['provider_profiles'] as Map<String, dynamic>;
    final profile = providerProfile['profiles'] as Map<String, dynamic>;
    final providerName = profile['full_name'] as String? ?? 'Provider';
    final avatarUrl = profile['avatar_url'] as String?;
    final hourlyRate = (providerProfile['hourly_rate'] as num?)?.toDouble() ?? 0.0;
    final description = widget.video['description'] as String?;
    final providerId = widget.video['provider_id'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            if (_hasError)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            else if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              GestureDetector(
                onTap: _togglePlayPause,
                child: VideoPlayer(_controller),
              ),

            // Play/Pause overlay
            if (_isInitialized && !_hasError)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 0.7,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

            // Provider info overlay (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Provider name and avatar
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  providerName[0].toUpperCase(),
                                  style: const TextStyle(
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
                                providerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'N\$${hourlyRate.toStringAsFixed(2)}/hour',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // View Profile button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to provider detail screen with provider data
                          context.push(
                            '/provider-detail/$providerId',
                            extra: {
                              'id': providerId,
                              'hourly_rate': hourlyRate,
                              'bio': providerProfile['bio'],
                              'skills': providerProfile['skills'] ?? [],
                              'profiles': profile,
                              'contact_number': profile['contact_number'],
                            },
                          );
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('View Profile & Book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
