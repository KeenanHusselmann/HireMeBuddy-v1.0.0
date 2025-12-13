import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_stats.dart';
import '../models/user_info.dart';
import '../models/provider_info.dart';
import '../models/analytics_data.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // Get dashboard statistics
  Future<AdminStats> getDashboardStats() async {
    try {
      // Get total users count
      final usersData = await _supabase
          .from('profiles')
          .select('id');
      final totalUsers = (usersData as List).length;

      // Get active providers count
      final providersData = await _supabase
          .from('provider_profiles')
          .select('id')
          .eq('is_available', true);
      final activeProviders = (providersData as List).length;

      // Get total bookings count
      final bookingsData = await _supabase
          .from('bookings')
          .select('id');
      final totalBookings = (bookingsData as List).length;

      // Calculate total revenue from completed bookings
      final revenueData = await _supabase
          .from('bookings')
          .select('total_price')
          .eq('status', 'completed');

      double totalRevenue = 0;
      for (var booking in revenueData) {
        if (booking['total_price'] != null) {
          totalRevenue += (booking['total_price'] as num).toDouble();
        }
      }

      // Get pending bookings count
      final pendingData = await _supabase
          .from('bookings')
          .select('id')
          .eq('status', 'pending');
      final pendingBookings = (pendingData as List).length;

      // Get bookings completed today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final completedTodayData = await _supabase
          .from('bookings')
          .select('id')
          .eq('status', 'completed')
          .gte('updated_at', todayStart.toIso8601String())
          .lt('updated_at', todayEnd.toIso8601String());
      final completedToday = (completedTodayData as List).length;

      return AdminStats(
        totalUsers: totalUsers,
        activeProviders: activeProviders,
        totalBookings: totalBookings,
        totalRevenue: totalRevenue,
        pendingBookings: pendingBookings,
        completedToday: completedToday,
      );
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  // Get all users with pagination
  Future<List<UserInfo>> getAllUsers({int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            email,
            phone,
            created_at,
            updated_at
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => UserInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // Get all providers with their details
  Future<List<ProviderInfo>> getAllProviders({int limit = 50, int offset = 0}) async {
    try {
      // Query from profiles table where role is provider, then LEFT JOIN to provider_profiles
      // Use explicit foreign key name to avoid ambiguity with documents_reviewed_by relationship
      final response = await _supabase
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
              service_photos_urls
            )
          ''')
          .eq('role', 'provider')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((json) => ProviderInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load providers: $e');
    }
  }

  // Verify a provider
  Future<void> verifyProvider(String providerId, bool isVerified) async {
    try {
      // Debug: Check current auth session
      final currentUser = _supabase.auth.currentUser;
      print('🔍 [ADMIN] Current user: ${currentUser?.id}');
      print('🔍 [ADMIN] Current user email: ${currentUser?.email}');
      
      if (currentUser == null) {
        throw Exception('Not authenticated. Please logout and login again.');
      }
      
      // Check if current user is admin
      final adminProfile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();
      
      print('🔍 [ADMIN] Admin profile role: ${adminProfile?['role']}');
      
      if (adminProfile == null || adminProfile['role'] != 'admin') {
        throw Exception('Unauthorized. Admin role required.');
      }
      
      // Check if provider_profiles record exists
      final existing = await _supabase
          .from('provider_profiles')
          .select('id')
          .eq('id', providerId)
          .maybeSingle();
      
      if (existing == null) {
        print('🔧 [ADMIN] Creating provider_profiles record for $providerId');
        // Create a basic provider_profiles record if it doesn't exist
        await _supabase
            .from('provider_profiles')
            .insert({
              'id': providerId,
              'is_verified': isVerified,
              'is_available': true,
              'bio': 'Provider profile pending completion',
              'hourly_rate': 0,
            });
      } else {
        print('🔧 [ADMIN] Updating existing provider_profiles for $providerId');
        // Update existing record
        await _supabase
            .from('provider_profiles')
            .update({'is_verified': isVerified})
            .eq('id', providerId);
      }
      
      print('✅ [ADMIN] Provider verification updated successfully');
    } catch (e) {
      print('❌ [ADMIN] Error verifying provider: $e');
      throw Exception('Failed to verify provider: $e');
    }
  }

  // Toggle provider active status
  Future<void> toggleProviderStatus(String providerId, bool isAvailable) async {
    try {
      // Check if provider_profiles record exists
      final existing = await _supabase
          .from('provider_profiles')
          .select('id')
          .eq('id', providerId)
          .maybeSingle();
      
      if (existing == null) {
        // Create a basic provider_profiles record if it doesn't exist
        await _supabase
            .from('provider_profiles')
            .insert({
              'id': providerId,
              'is_available': isAvailable,
              'is_verified': false,
              'bio': 'Provider profile pending completion',
              'hourly_rate': 0,
            });
      } else {
        // Update existing record
        await _supabase
            .from('provider_profiles')
            .update({'is_available': isAvailable})
            .eq('id', providerId);
      }
    } catch (e) {
      throw Exception('Failed to update provider status: $e');
    }
  }

  // Get all bookings with details
  Future<List<Map<String, dynamic>>> getAllBookings({int limit = 100, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            client_id,
            provider_id,
            booking_date,
            booking_time,
            duration_hours,
            hourly_rate,
            total_price,
            status,
            notes,
            created_at,
            profiles!client_id (
              full_name,
              email,
              phone
            )
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response;
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  // Delete a user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Search users by name or email
  Future<List<UserInfo>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            email,
            phone,
            created_at,
            updated_at
          ''')
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => UserInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get booking statistics by status
  Future<Map<String, int>> getBookingStatsByStatus() async {
    try {
      final allBookings = await _supabase
          .from('bookings')
          .select('status');

      Map<String, int> stats = {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (var booking in allBookings) {
        String status = booking['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to load booking stats: $e');
    }
  }

  // Get all services with provider counts
  Future<List<Map<String, dynamic>>> getAllServices({int limit = 100, int offset = 0}) async {
    try {
      // Use SQL to efficiently count providers with a single query
      final response = await _supabase.rpc('get_services_with_provider_count');
      
      // If the RPC doesn't exist, fall back to manual counting
      if (response == null) {
        return _getServicesManually(limit, offset);
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback to manual counting if RPC fails
      print('⚠️ RPC failed, using manual count: $e');
      return _getServicesManually(limit, offset);
    }
  }

  // Fallback method to manually count providers
  Future<List<Map<String, dynamic>>> _getServicesManually(int limit, int offset) async {
    final response = await _supabase
        .from('service_categories')
        .select('id, name, description, created_at')
        .order('name', ascending: true)
        .range(offset, offset + limit - 1);

    // Get ALL provider services in one query for efficiency
    print('🔍 Fetching all provider_services...');
    final allProviderServices = await _supabase
        .from('provider_services')
        .select('service_category_id, provider_id, id, created_at');

    print('📋 Total provider_services entries: ${allProviderServices.length}');
    
    if (allProviderServices.isEmpty) {
      print('⚠️ WARNING: provider_services table is EMPTY!');
      print('   This means no providers have been registered with services yet.');
      print('   Make sure providers complete registration and add services.');
    } else {
      print('✅ Found provider_services data:');
      for (var ps in allProviderServices.take(5)) {
        print('   - Service Category ID: ${ps['service_category_id']}');
        print('     Provider ID: ${ps['provider_id']}');
        print('     Created: ${ps['created_at']}');
      }
      if (allProviderServices.length > 5) {
        print('   ... and ${allProviderServices.length - 5} more');
      }
    }
    
    // Group by service_category_id
    Map<String, int> countsByCategory = {};
    for (var ps in allProviderServices) {
      final categoryId = ps['service_category_id'] as String;
      countsByCategory[categoryId] = (countsByCategory[categoryId] ?? 0) + 1;
    }

    print('📊 Provider counts by category ID:');
    countsByCategory.forEach((categoryId, count) {
      print('   $categoryId: $count providers');
    });

    List<Map<String, dynamic>> servicesWithCounts = [];
    for (var service in response) {
      final serviceId = service['id'] as String;
      final count = countsByCategory[serviceId] ?? 0;
      
      if (count > 0) {
        print('✅ ${service['name']}: $count providers');
      }

      servicesWithCounts.add({
        ...service,
        'provider_count': count,
      });
    }

    return servicesWithCounts;
  }

  // Add a new service
  Future<void> addService({
    required String name,
    String? description,
    String? category,
  }) async {
    try {
      await _supabase.from('service_categories').insert({
        'name': name,
        'description': description ?? '',
      });
    } catch (e) {
      throw Exception('Failed to add service: $e');
    }
  }

  // Update a service
  Future<void> updateService({
    required String serviceId,
    required String name,
    String? description,
    String? category,
  }) async {
    try {
      await _supabase.from('service_categories').update({
        'name': name,
        'description': description ?? '',
      }).eq('id', serviceId);
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    try {
      await _supabase
          .from('service_categories')
          .delete()
          .eq('id', serviceId);
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  // Get analytics data for charts
  Future<AnalyticsData> getAnalyticsData() async {
    try {
      // Revenue trend - last 7 days
      final revenueTrend = await _getRevenueTrend();
      
      // Bookings by status
      final bookingsByStatus = await _getBookingsByStatus();
      
      // Top services
      final topServices = await _getTopServices();
      
      // Provider growth
      final providerGrowth = await _getProviderGrowth();

      return AnalyticsData(
        revenueTrend: revenueTrend,
        bookingsByStatus: bookingsByStatus,
        topServices: topServices,
        providerGrowth: providerGrowth,
      );
    } catch (e) {
      throw Exception('Failed to load analytics data: $e');
    }
  }

  Future<List<DailyRevenue>> _getRevenueTrend() async {
    final now = DateTime.now();
    final List<DailyRevenue> trend = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final bookings = await _supabase
          .from('bookings')
          .select('total_price, status')
          .gte('created_at', date.toIso8601String())
          .lt('created_at', nextDate.toIso8601String());

      double revenue = 0;
      int count = 0;
      for (var booking in bookings) {
        if (booking['total_price'] != null) {
          revenue += (booking['total_price'] as num).toDouble();
          count++;
        }
      }

      trend.add(DailyRevenue(
        date: date,
        revenue: revenue,
        bookings: count,
      ));
    }

    return trend;
  }

  Future<Map<String, int>> _getBookingsByStatus() async {
    final bookings = await _supabase
        .from('bookings')
        .select('status');

    final Map<String, int> statusCounts = {};
    for (var booking in bookings) {
      final status = booking['status'] as String;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return statusCounts;
  }

  Future<List<ServicePopularity>> _getTopServices() async {
    // Get all service categories
    final services = await _supabase
        .from('service_categories')
        .select('id, name')
        .limit(20);

    final List<ServicePopularity> popularity = [];

    // Since bookings table doesn't have service_category_id in the deployed schema,
    // we'll count by provider services instead
    for (var service in services) {
      final serviceId = service['id'] as String;
      
      // Get providers offering this service
      final providerServices = await _supabase
          .from('provider_services')
          .select('provider_id')
          .eq('service_category_id', serviceId);

      if (providerServices.isEmpty) continue;

      // Get bookings for these providers
      final providerIds = providerServices.map((ps) => ps['provider_id']).toList();
      int totalBookings = 0;
      double totalRevenue = 0;

      for (var providerId in providerIds) {
        final bookings = await _supabase
            .from('bookings')
            .select('total_price, id')
            .eq('provider_id', providerId);

        totalBookings += bookings.length;
        for (var booking in bookings) {
          if (booking['total_price'] != null) {
            totalRevenue += (booking['total_price'] as num).toDouble();
          }
        }
      }

      if (totalBookings > 0) {
        popularity.add(ServicePopularity(
          name: service['name'] as String,
          bookings: totalBookings,
          revenue: totalRevenue,
        ));
      }
    }

    // Sort by bookings count and take top 5
    popularity.sort((a, b) => b.bookings.compareTo(a.bookings));
    return popularity.take(5).toList();
  }

  Future<List<MonthlyGrowth>> _getProviderGrowth() async {
    final now = DateTime.now();
    final List<MonthlyGrowth> growth = [];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final providers = await _supabase
          .from('provider_profiles')
          .select('id')
          .gte('created_at', month.toIso8601String())
          .lt('created_at', nextMonth.toIso8601String());

      final users = await _supabase
          .from('profiles')
          .select('id')
          .gte('created_at', month.toIso8601String())
          .lt('created_at', nextMonth.toIso8601String());

      growth.add(MonthlyGrowth(
        month: monthNames[month.month - 1],
        providers: providers.length,
        users: users.length,
      ));
    }

    return growth;
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _supabase
        .from('bookings')
        .update({'status': newStatus})
        .eq('id', bookingId);
  }
}
