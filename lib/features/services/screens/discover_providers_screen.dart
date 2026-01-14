import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/provider_video_feed.dart';

class DiscoverProvidersScreen extends ConsumerWidget {
  const DiscoverProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text(
          'Discover Providers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false, // Remove back button for bottom nav screen
      ),
      body: ListView(
        children: const [
          SizedBox(height: 16),
          ProviderVideoFeed(),
          SizedBox(height: 80), // Bottom padding for nav bar
        ],
      ),
    );
  }
}
