import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../models/provider_profile.dart';
import '../models/service_category.dart';

class ProviderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create or update provider profile
  Future<ProviderProfile> createProviderProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String bio,
    required List<String> skills,
    required double hourlyRate,
  }) async {
    try {
      logger.debug('ProviderService: Creating provider profile for user: $userId');
      logger.debug('ProviderService: First name: $firstName');
      logger.debug('ProviderService: Last name: $lastName');
      logger.debug('ProviderService: Bio: $bio');
      logger.debug('ProviderService: Skills: $skills');
      logger.debug('ProviderService: Hourly rate: $hourlyRate');
      
      // First, ensure the profile exists in the profiles table and update name fields
      logger.debug('ProviderService: Checking if profile exists in profiles table...');
      final profileCheck = await _supabase
          .from('profiles')
          .select('id, role, full_name')
          .eq('id', userId)
          .maybeSingle();
      
      if (profileCheck == null) {
        logger.error('ProviderService: ERROR - Profile not found! User must complete signup first.', Exception('Profile not found'));
        throw Exception('User profile not found. Please ensure you are logged in.');
      }
      
      // Update role to provider and update name fields
      logger.debug('ProviderService: Updating user role to provider and name fields...');
      await _supabase.from('profiles').update({
        'role': 'provider',
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      logger.debug('ProviderService: User profile updated');
      
      // Now create the provider profile - pending verification by admin
      final response = await _supabase
          .from('provider_profiles')
          .insert({
            'id': userId,
            'bio': bio,
            'skills': skills,
            'hourly_rate': hourlyRate,
            'is_verified': false,  // Pending admin verification
            'is_available': true,
          })
          .select()
          .single();

      logger.info('ProviderService: Provider profile created successfully (pending verification): ${response['id']}');
      return ProviderProfile.fromJson(response);
    } catch (e) {
      logger.error('ProviderService: ERROR creating provider profile', e);
      throw Exception('Failed to create provider profile: $e');
    }
  }

  // Update provider profile
  Future<ProviderProfile> updateProviderProfile({
    required String userId,
    String? bio,
    List<String>? skills,
    double? hourlyRate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (bio != null) updates['bio'] = bio;
      if (skills != null) updates['skills'] = skills;
      if (hourlyRate != null) updates['hourly_rate'] = hourlyRate;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('provider_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return ProviderProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update provider profile: $e');
    }
  }

  // Get provider profile
  Future<ProviderProfile?> getProviderProfile(String userId) async {
    try {
      final response = await _supabase
          .from('provider_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProviderProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get provider profile: $e');
    }
  }

  // Add service to provider
  Future<void> addProviderService({
    required String providerId,
    required String categoryId,
    required String description,
    required double basePrice,
  }) async {
    try {
      logger.debug('ProviderService: Adding service - Provider: $providerId, Category: $categoryId');
      
      await _supabase.from('provider_services').insert({
        'provider_id': providerId,
        'service_category_id': categoryId,  // Changed from category_id
        'description': description,
        'base_price': basePrice,
        'is_available': true,
      });
      
      logger.info('ProviderService: Service added successfully');
    } on PostgrestException catch (e) {
      logger.error('ProviderService: PostgrestException adding service: ${e.message}', e);
      // Check if it's a unique constraint violation
      if (e.code == '23505' || e.message.toLowerCase().contains('duplicate') || 
          e.message.toLowerCase().contains('unique')) {
        throw Exception('You have already added this service category');
      }
      throw Exception('Failed to add service: ${e.message}');
    } catch (e) {
      logger.error('ProviderService: ERROR adding service', e);
      throw Exception('Failed to add provider service: $e');
    }
  }

  // Create a custom service category (or get existing one)
  Future<String> createCustomCategory(String categoryName) async {
    try {
      // First, check if category already exists
      final existing = await _supabase
          .from('service_categories')
          .select('id')
          .eq('name', categoryName)
          .maybeSingle();
      
      if (existing != null) {
        return existing['id'] as String;
      }
      
      // Create new category if it doesn't exist
      final response = await _supabase
          .from('service_categories')
          .insert({
            'name': categoryName,
            'description': 'Custom service category',
          })
          .select('id')
          .single();
      
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create custom category: $e');
    }
  }

  // Get all service categories
  Future<List<ServiceCategory>> getServiceCategories() async {
    try {
      final response = await _supabase
          .from('service_categories')
          .select()
          .order('name');

      return (response as List)
          .map((json) => ServiceCategory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get service categories: $e');
    }
  }

  // Get provider's services
  Future<List<Map<String, dynamic>>> getProviderServices(String providerId) async {
    try {
      final response = await _supabase
          .from('provider_services')
          .select('*, service_categories(*)')
          .eq('provider_id', providerId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get provider services: $e');
    }
  }

  // Update provider service availability
  Future<void> updateServiceAvailability({
    required String serviceId,
    required bool isAvailable,
  }) async {
    try {
      await _supabase
          .from('provider_services')
          .update({'is_available': isAvailable})
          .eq('id', serviceId);
    } catch (e) {
      throw Exception('Failed to update service availability: $e');
    }
  }

  // Update provider service
  Future<void> updateProviderService({
    required String serviceId,
    required double basePrice,
    required String description,
  }) async {
    try {
      logger.debug('ProviderService: Updating service: $serviceId');
      await _supabase
          .from('provider_services')
          .update({
            'base_price': basePrice,
            'description': description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', serviceId);
      logger.info('ProviderService: Service updated successfully');
    } catch (e) {
      logger.error('ProviderService: ERROR updating service', e);
      throw Exception('Failed to update service: $e');
    }
  }

  // Delete provider service
  Future<void> deleteProviderService(String serviceId) async {
    try {
      logger.debug('ProviderService: Deleting service: $serviceId');
      await _supabase
          .from('provider_services')
          .delete()
          .eq('id', serviceId);
      logger.info('ProviderService: Service deleted successfully');
    } catch (e) {
      logger.error('ProviderService: ERROR deleting service', e);
      throw Exception('Failed to delete service: $e');
    }
  }

  // Get all providers with their profiles
  Future<List<Map<String, dynamic>>> getAllProviders() async {
    try {
      logger.debug('ProviderService: Querying provider_profiles...');
      
      // First, try without join to see if we get any data
      final simpleResponse = await _supabase
          .from('provider_profiles')
          .select('*');
      
      logger.debug('ProviderService: Simple query (no join) returned: ${simpleResponse.length} rows');
      
      // Use the foreign key constraint name
      final response = await _supabase
          .from('provider_profiles')
          .select('''
            *,
            profiles:provider_profiles_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .order('created_at', ascending: false);

      logger.debug('ProviderService: Raw response: $response');
      logger.debug('ProviderService: Response type: ${response.runtimeType}');
      logger.debug('ProviderService: Response length: ${(response as List).length}');
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      logger.error('ProviderService: ERROR in getAllProviders', e);
      throw Exception('Failed to get providers: $e');
    }
  }

  // Get providers by service category
  Future<List<Map<String, dynamic>>> getProvidersByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('provider_services')
          .select('''
            provider_id,
            description,
            base_price,
            provider_profiles!inner(
              *,
              profiles!inner(
                id,
                email,
                full_name,
                phone_number,
                avatar_url
              )
            )
          ''')
          .eq('category_id', categoryId)
          .eq('is_available', true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get providers by category: $e');
    }
  }
}
