import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../models/booking.dart';
import '../models/booking_with_client.dart';
import '../models/booking_with_provider.dart';

class BookingService {
  final _supabase = Supabase.instance.client;

  Future<Booking> createBooking({
    required String providerId,
    required DateTime bookingDate,
    required String bookingTime,
    required int durationHours,
    required double hourlyRate,
    String? notes,
    String? jobLocation,
    String? jobInstructions,
    double? clientBudget,
    String? secondaryContact,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the profile ID from profiles table
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final clientId = profileResponse['id'] as String;
      final totalPrice = hourlyRate * durationHours;

      final response = await _supabase.from('bookings').insert({
        'client_id': clientId,
        'provider_id': providerId,
        'booking_date': bookingDate.toIso8601String().split('T')[0],
        'booking_time': bookingTime,
        'duration_hours': durationHours,
        'hourly_rate': hourlyRate,
        'total_price': totalPrice,
        'notes': notes,
        'job_location': jobLocation,
        'job_instructions': jobInstructions,
        'client_budget': clientBudget,
        'secondary_contact': secondaryContact,
        'status': 'pending',
      }).select().single();

      logger.info('BookingService: Booking created successfully');
      return Booking.fromJson(response);
    } catch (e) {
      logger.error('BookingService: Error creating booking', e);
      rethrow;
    }
  }

  Future<List<Booking>> getClientBookings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the profile ID from profiles table
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final clientId = profileResponse['id'] as String;

      final response = await _supabase
          .from('bookings')
          .select()
          .eq('client_id', clientId)
          .order('booking_date', ascending: false);

      logger.info('BookingService: Fetched ${response.length} client bookings');
      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      logger.error('BookingService: Error fetching client bookings', e);
      rethrow;
    }
  }

  Future<List<Booking>> getProviderBookings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the profile ID from profiles table
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final providerId = profileResponse['id'] as String;

      final response = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', providerId)
          .order('booking_date', ascending: false);

      logger.info('BookingService: Fetched ${response.length} provider bookings');
      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      logger.error('BookingService: Error fetching provider bookings', e);
      rethrow;
    }
  }

  Future<List<BookingWithClient>> getProviderBookingsWithClientDetails() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the profile ID from profiles table
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final providerId = profileResponse['id'] as String;

      // Fetch bookings first
      final bookingsResponse = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', providerId)
          .order('booking_date', ascending: false);

      logger.info('BookingService: Fetched ${bookingsResponse.length} provider bookings');
      
      // Extract unique client IDs
      final clientIds = bookingsResponse
          .map((b) => b['client_id'] as String)
          .toSet()
          .toList();
      
      // Fetch ALL client details in a SINGLE query (massive performance improvement)
      final clientProfiles = clientIds.isEmpty 
          ? <String, Map<String, dynamic>>{}
          : await _supabase
              .from('profiles')
              .select('id, full_name, phone, email')
              .inFilter('id', clientIds)
              .then((response) => Map.fromEntries(
                    response.map((profile) => MapEntry(
                          profile['id'] as String,
                          profile,
                        )),
                  ));
      
      logger.info('BookingService: Fetched ${clientProfiles.length} client profiles in single query');
      
      // Build bookings with client details from the cached map
      final List<BookingWithClient> bookingsWithClients = bookingsResponse.map((bookingJson) {
        final clientId = bookingJson['client_id'] as String;
        final clientProfile = clientProfiles[clientId];
        
        return BookingWithClient.fromJson({
          ...bookingJson,
          'client_name': clientProfile?['full_name'] ?? 'Unknown Client',
          'client_phone': clientProfile?['phone'],
          'client_email': clientProfile?['email'],
          'client_profile_image': null,
        });
      }).toList();
      
      return bookingsWithClients;
    } catch (e) {
      logger.error('BookingService: Error fetching provider bookings with client details', e);
      rethrow;
    }
  }

  Stream<List<BookingWithProvider>> getClientBookingsWithProviderDetails() async* {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // Get the profile ID (user.id is the profile ID)
      final clientId = user.id;

      logger.info('BookingService: Setting up real-time stream for client bookings: $clientId');

      // Stream bookings and fetch provider details on each update
      await for (final bookingsData in _supabase
          .from('bookings')
          .stream(primaryKey: ['id'])) {
        
        // Filter for this client's bookings
        final clientBookings = bookingsData
            .where((b) => b['client_id'] == clientId)
            .toList();
        
        if (clientBookings.isEmpty) {
          logger.info('BookingService: No bookings found for client');
          yield [];
          continue;
        }

        logger.info('BookingService: Fetched ${clientBookings.length} client bookings');
        
        // Extract unique provider IDs
        final providerIds = clientBookings
            .map((b) => b['provider_id'] as String)
            .toSet()
            .toList();
        
        // Fetch ALL provider details in a SINGLE query
        final providerProfiles = providerIds.isEmpty 
            ? <String, Map<String, dynamic>>{}
            : await _supabase
                .from('profiles')
                .select('id, full_name, phone, avatar_url')
                .inFilter('id', providerIds)
                .then((response) => Map.fromEntries(
                      response.map((profile) => MapEntry(
                            profile['id'] as String,
                            profile,
                          )),
                    ));
        
        logger.info('BookingService: Fetched ${providerProfiles.length} provider profiles in single query');
        
        // Build bookings with provider details
        final bookingsWithProviders = clientBookings.map((bookingJson) {
          final booking = Booking.fromJson(bookingJson);
          final providerProfile = providerProfiles[booking.providerId];
          
          return BookingWithProvider(
            booking: booking,
            providerName: providerProfile?['full_name'] as String? ?? 'Unknown Provider',
            providerPhone: providerProfile?['phone'] as String?,
            providerAvatar: providerProfile?['avatar_url'] as String?,
          );
        }).toList();
        
        // Sort by booking date descending
        bookingsWithProviders.sort((a, b) => 
            b.booking.bookingDate.compareTo(a.booking.bookingDate));
        
        yield bookingsWithProviders;
      }
    } catch (e) {
      logger.error('BookingService: Error fetching client bookings with provider details', e);
      yield [];
    }
  }

  Future<int> getPendingBookingsCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // user.id is the profile ID
      final providerId = user.id;

      final response = await _supabase
          .from('bookings')
          .select('id')
          .eq('provider_id', providerId)
          .eq('status', 'pending')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      logger.error('BookingService: Error counting pending bookings', e);
      return 0;
    }
  }

  Future<int> getClientPendingBookingsCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // user.id is the profile ID
      final clientId = user.id;

      final response = await _supabase
          .from('bookings')
          .select('id')
          .eq('client_id', clientId)
          .eq('status', 'pending')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      logger.error('BookingService: Error counting client pending bookings', e);
      return 0;
    }
  }

  Future<void> updateBookingStatus(
    String bookingId, 
    String status, {
    String? completionNotes,
    String? workCompleted,
    String? issuesEncountered,
  }) async {
    try {
      final updateData = {
        'status': status,
      };

      // Add completion details if completing the job
      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        if (completionNotes != null) updateData['completion_notes'] = completionNotes;
        if (workCompleted != null) updateData['work_completed'] = workCompleted;
        if (issuesEncountered != null) updateData['issues_encountered'] = issuesEncountered;
      }

      await _supabase.from('bookings').update(updateData).eq('id', bookingId);

      logger.info('BookingService: Updated booking $bookingId status to $status');
    } catch (e) {
      logger.error('BookingService: Error updating booking status', e);
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await updateBookingStatus(bookingId, 'cancelled');
      logger.info('BookingService: Cancelled booking $bookingId');
    } catch (e) {
      logger.error('BookingService: Error cancelling booking', e);
      rethrow;
    }
  }
}
