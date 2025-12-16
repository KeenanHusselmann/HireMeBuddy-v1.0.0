class Booking {
  final String id;
  final String jobNumber;
  final String clientId;
  final String providerId;
  final DateTime bookingDate;
  final String bookingTime;
  final int durationHours;
  final double hourlyRate;
  final double totalPrice;
  final String? notes;
  final String? jobLocation;
  final String? jobInstructions;
  final double? clientBudget;
  final String? secondaryContact;
  final String? completionNotes;
  final String? workCompleted;
  final String? issuesEncountered;
  final DateTime? completedAt;
  final String paymentStatus;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.jobNumber,
    required this.clientId,
    required this.providerId,
    required this.bookingDate,
    required this.bookingTime,
    required this.durationHours,
    required this.hourlyRate,
    required this.totalPrice,
    this.notes,
    this.jobLocation,
    this.jobInstructions,
    this.clientBudget,
    this.secondaryContact,
    this.completionNotes,
    this.workCompleted,
    this.issuesEncountered,
    this.completedAt,
      required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      jobNumber: json['job_number'] as String? ?? 'JOB-${json['id'].toString().substring(0, 8).toUpperCase()}',
      clientId: json['client_id'] as String,
      providerId: json['provider_id'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      bookingTime: json['booking_time'] as String,
      durationHours: json['duration_hours'] as int,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String?,
      jobLocation: json['job_location'] as String?,
      jobInstructions: json['job_instructions'] as String?,
      clientBudget: json['client_budget'] != null ? (json['client_budget'] as num).toDouble() : null,
      secondaryContact: json['secondary_contact'] as String?,
      completionNotes: json['completion_notes'] as String?,
      workCompleted: json['work_completed'] as String?,
      issuesEncountered: json['issues_encountered'] as String?,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      paymentStatus: 'pending', // Payment status determined by checking payments table
      status: BookingStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_number': jobNumber,
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
      'completion_notes': completionNotes,
      'work_completed': workCompleted,
      'issues_encountered': issuesEncountered,
      'completed_at': completedAt?.toIso8601String(),
      'payment_status': paymentStatus,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}
