import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/services/provider_service.dart';
import '../../shared/models/provider_profile.dart';
import '../../shared/models/service_category.dart';

// Provider Service instance
final providerServiceProvider = Provider<ProviderService>((ref) {
  return ProviderService();
});

// Service Categories Provider
final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final service = ref.watch(providerServiceProvider);
  return service.getServiceCategories();
});

// Provider Profile Provider - Real-time stream for instant updates
final providerProfileProvider = StreamProvider.family<ProviderProfile?, String>((ref, userId) async* {
  final supabase = Supabase.instance.client;
  
  // Stream provider_profiles for real-time updates (e.g., verification status)
  await for (final profiles in supabase
      .from('provider_profiles')
      .stream(primaryKey: ['id'])
      .eq('id', userId)) {
    
    if (profiles.isEmpty) {
      yield null;
    } else {
      final data = profiles.first;
      yield ProviderProfile.fromJson(data);
    }
  }
});

// Provider Services Provider
final providerServicesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) async {
  final service = ref.watch(providerServiceProvider);
  return service.getProviderServices(providerId);
});

// Real-time Providers Stream Provider
final allProvidersStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  
  print('🔴 [REALTIME] Setting up stream for provider_profiles table');
  
  // Simple direct stream approach - no caching, just pure real-time
  return supabase
      .from('provider_profiles')
      .stream(primaryKey: ['id'])
      .asyncMap((providerProfiles) async {
        print('🟢 [REALTIME] Stream event received with ${providerProfiles.length} providers');
        
        final List<Map<String, dynamic>> providersWithProfiles = [];
        
        for (var providerProfile in providerProfiles) {
          try {
            final providerId = providerProfile['id'] as String;
            
            // Fetch the user profile
            final userProfile = await supabase
                .from('profiles')
                .select()
                .eq('id', providerId)
                .maybeSingle();
            
            if (userProfile != null) {
              final mergedData = {
                ...providerProfile,
                'profiles': userProfile,
              };
              
              print('✅ [REALTIME] Provider ${userProfile['full_name']} - Available: ${providerProfile['is_available']}');
              providersWithProfiles.add(mergedData);
            }
          } catch (e) {
            print('❌ [REALTIME] Error for provider ${providerProfile['id']}: $e');
          }
        }
        
        print('📊 [REALTIME] Returning ${providersWithProfiles.length} providers to UI');
        return providersWithProfiles;
      });
});

// Provider Registration State
class ProviderRegistrationState {
  final bool isLoading;
  final String? error;
  final ProviderProfile? profile;

  ProviderRegistrationState({
    this.isLoading = false,
    this.error,
    this.profile,
  });

  ProviderRegistrationState copyWith({
    bool? isLoading,
    String? error,
    ProviderProfile? profile,
  }) {
    return ProviderRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
    );
  }
}

// Provider Registration Notifier
class ProviderRegistrationNotifier extends StateNotifier<ProviderRegistrationState> {
  final ProviderService _providerService;

  ProviderRegistrationNotifier(this._providerService)
      : super(ProviderRegistrationState());

  Future<void> registerProvider({
    required String userId,
    required String bio,
    required List<String> skills,
    required double hourlyRate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _providerService.createProviderProfile(
        userId: userId,
        bio: bio,
        skills: skills,
        hourlyRate: hourlyRate,
      );

      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProvider({
    required String userId,
    String? bio,
    List<String>? skills,
    double? hourlyRate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _providerService.updateProviderProfile(
        userId: userId,
        bio: bio,
        skills: skills,
        hourlyRate: hourlyRate,
      );

      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addService({
    required String providerId,
    required String categoryId,
    required String description,
    required double basePrice,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _providerService.addProviderService(
        providerId: providerId,
        categoryId: categoryId,
        description: description,
        basePrice: basePrice,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider Registration State Provider
final providerRegistrationProvider =
    StateNotifierProvider<ProviderRegistrationNotifier, ProviderRegistrationState>((ref) {
  final service = ref.watch(providerServiceProvider);
  return ProviderRegistrationNotifier(service);
});
