import 'booking.dart';

class BookingWithClient {
  final Booking booking;
  final String clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientProfileImage;

  BookingWithClient({
    required this.booking,
    required this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.clientProfileImage,
  });

  factory BookingWithClient.fromJson(Map<String, dynamic> json) {
    return BookingWithClient(
      booking: Booking.fromJson(json),
      clientName: json['client_name'] as String? ?? 'Unknown Client',
      clientPhone: json['client_phone'] as String?,
      clientEmail: json['client_email'] as String?,
      clientProfileImage: json['client_profile_image'] as String?,
    );
  }
}
