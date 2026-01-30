import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/utils/logger.dart';

// Provider for fetching random provider videos with real-time updates
final randomProviderVideosProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  
  logger.info('🔴 Setting up real-time stream for video feed (provider_profiles)');
  
  // Use the same real-time stream approach as Browse Services
  return supabase
      .from('provider_profiles')
      .stream(primaryKey: ['id'])
      .asyncMap((providerProfiles) async {
        logger.info('🟢 Video feed: Stream event received with ${providerProfiles.length} provider profiles');
        
        try {
          // Fetch ALL providers with their profiles
          final List<Map<String, dynamic>> providerCards = [];
          
          for (var providerProfile in providerProfiles) {
            final providerId = providerProfile['id'] as String;
            try {
              // Fetch the user profile
              final userProfile = await supabase
                  .from('profiles')
                  .select()
                  .eq('id', providerId)
                  .maybeSingle();
              
              if (userProfile == null) continue;
              
              // Try to get a video for this provider
              final videos = await supabase
                  .from('portfolio_images')
                  .select('id, image_url, description')
                  .eq('provider_id', providerId)
                  .eq('media_type', 'video')
                  .limit(1);
              
              // Only add providers who have videos
              if (videos.isNotEmpty) {
                final cardData = {
                  ...videos.first,
                  'provider_id': providerId,
                  'provider_profiles': {
                    ...providerProfile,
                    'profiles': userProfile,
                  },
                };
                providerCards.add(cardData);
              }
            } catch (e) {
              logger.error('Error fetching provider $providerId', e);
            }
          }
          
          // Shuffle for variety
          providerCards.shuffle();
          final randomCards = providerCards.take(20).toList();
          
          logger.info('📊 Video feed: Returning ${randomCards.length} provider cards to UI');
          return randomCards;
        } catch (e) {
          logger.error('Error fetching random videos', e);
          return [];
        }
      });
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
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.teal),
                    onPressed: () {
                      ref.invalidate(randomProviderVideosProvider);
                    },
                    tooltip: 'Refresh providers',
                  ),
                ],
              ),
            ),
            // Build videos as direct children instead of nested scroll
            ...videos.map((video) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: SizedBox(
                height: 460,
                child: VideoCard(video: video),
              ),
            )),
            const SizedBox(height: 100),
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
      // Check if video URL exists and is valid
      final videoUrl = widget.video['image_url'] as String?;
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Invalid video URL');
      }

      // Try to get cached video first
      try {
        final fileInfo = await DefaultCacheManager().getFileFromCache(videoUrl);
        
        if (fileInfo != null && fileInfo.file.existsSync()) {
          // Use cached file
          _controller = VideoPlayerController.file(fileInfo.file);
          logger.debug('📹 Using cached video for: $videoUrl');
        } else {
          // Download and cache the video
          final file = await DefaultCacheManager().getSingleFile(videoUrl);
          _controller = VideoPlayerController.file(file);
          logger.debug('📹 Downloaded and cached video: $videoUrl');
        }
      } catch (cacheError) {
        // If caching fails, fall back to network
        logger.debug('📹 Cache failed, using network: $cacheError');
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
      }
      
      // Initialize with timeout to prevent hanging
      await _controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video initialization timeout - may not be supported on this platform');
        },
      );
      
      _controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Video will autoplay when it becomes visible (handled by VisibilityDetector)
      }
    } on UnimplementedError {
      // Video player not implemented on this platform (e.g., Windows desktop)
      // Silently fall back to avatar display - this is expected behavior
      if (mounted) {
        setState(() {
          _hasError = true;
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

  @override
  Widget build(BuildContext context) {
    final providerProfile = widget.video['provider_profiles'] as Map<String, dynamic>;
    final profile = providerProfile['profiles'] as Map<String, dynamic>;
    final providerName = profile['full_name'] as String? ?? 'Provider';
    final avatarUrl = profile['avatar_url'] as String?;
    final hourlyRate = (providerProfile['hourly_rate'] as num?)?.toDouble() ?? 0.0;
    final isAvailable = providerProfile['is_available'] ?? false;
    final description = widget.video['description'] as String?;
    final providerId = widget.video['provider_id'] as String;
    
    logger.debug('VIDEO CARD: Provider $providerName - Available: $isAvailable');

    return VisibilityDetector(
      key: Key('video_${widget.video['id']}'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        
        // Play video when it's at least 50% visible
        if (visiblePercentage >= 50) {
          if (_isInitialized && !_hasError && !_controller.value.isPlaying) {
            _controller.play();
            logger.debug('▶️ Playing video for $providerName (${visiblePercentage.toInt()}% visible)');
          }
        } else {
          // Pause video when less than 50% visible
          if (_isInitialized && !_hasError && _controller.value.isPlaying) {
            _controller.pause();
            logger.debug('⏸️ Pausing video for $providerName (${visiblePercentage.toInt()}% visible)');
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
            // Video player or fallback
            if (_hasError)
              // Show provider avatar as fallback when video fails
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                              style: const TextStyle(fontSize: 40, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      providerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black87,
                          ),
                          Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 8,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              VideoPlayer(_controller),

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
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black87,
                                    ),
                                    Shadow(
                                      offset: Offset(0, 0),
                                      blurRadius: 8,
                                      color: Colors.black45,
                                    ),
                                  ],
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
                          logger.debug('Navigating with is_available: $isAvailable');
                          // Navigate to provider detail screen with provider data
                          context.push(
                            '/provider-detail/$providerId',
                            extra: {
                              'id': providerId,
                              'hourly_rate': hourlyRate,
                              'bio': providerProfile['bio'],
                              'skills': providerProfile['skills'] ?? [],
                              'is_available': isAvailable,
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
      ),
    );
  }
}

class ScrollIndicator extends StatefulWidget {
  const ScrollIndicator({super.key});

  @override
  State<ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Scroll up to view next provider',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
