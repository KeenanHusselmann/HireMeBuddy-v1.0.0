import 'booking.dart';

class BookingWithProvider {
  final Booking booking;
  final String providerName;  // Non-nullable with default in service
  final String? providerAvatar;
  final String? providerPhone;

  BookingWithProvider({
    required this.booking,
    required this.providerName,  // Required non-nullable
    this.providerAvatar,
    this.providerPhone,
  });

  factory BookingWithProvider.fromJson(Map<String, dynamic> json) {
    return BookingWithProvider(
      booking: Booking.fromJson(json),
      providerName: json['provider_name'] ?? 'Unknown Provider',
      providerAvatar: json['provider_avatar'],
      providerPhone: json['provider_phone'],
    );
  }
}
