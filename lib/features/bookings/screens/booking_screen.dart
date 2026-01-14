import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/services/booking_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> provider;

  const BookingScreen({
    super.key,
    required this.provider,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedHours = 1;
  final _notesController = TextEditingController();
  final _jobLocationController = TextEditingController();
  final _jobInstructionsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _secondaryContactController = TextEditingController();
  
  // Calendar/availability state
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isLoadingAvailability = false;
  Set<DateTime> _bookedDates = {};
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadProviderAvailability();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _jobLocationController.dispose();
    _jobInstructionsController.dispose();
    _budgetController.dispose();
    _secondaryContactController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderAvailability() async {
    setState(() => _isLoadingAvailability = true);
    
    try {
      final profile = widget.provider['profiles'] as Map<String, dynamic>;
      final providerId = profile['id'] as String;
      
      // Fetch all bookings for this provider that are pending, accepted, or in_progress
      final bookingService = BookingService();
      final response = await bookingService.getProviderBookedSlots(providerId);
      
      logger.debug('BookingScreen: Loaded ${response.length} booked slots');
      for (var slot in response) {
        logger.debug('  - ${slot['booking_date']} at ${slot['booking_time']} (${slot['duration_hours']}h) - ${slot['status']}');
      }
      
      setState(() {
        _bookedSlots = response;
        // Extract unique booked dates for calendar highlighting
        _bookedDates = response
            .map((slot) => DateTime.parse(slot['booking_date']))
            .toSet();
        _isLoadingAvailability = false;
      });
    } catch (e) {
      logger.error('BookingScreen: Error loading availability', e);
      setState(() => _isLoadingAvailability = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading availability: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime(DateTime.now().year, DateTime.now().month + 6, DateTime.now().day),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  leftChevronMargin: EdgeInsets.zero,
                  rightChevronMargin: EdgeInsets.zero,
                  headerPadding: EdgeInsets.symmetric(vertical: 8),
                  titleTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekHeight: 40,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  canMarkersOverflow: false,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_isDateBooked(day)) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    if (_isDateBooked(day)) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade400, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                    // Show today's highlight even if not booked
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                    return;
                  }
                  
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTime = null; // Reset time when date changes
                  });
                  
                  // Show info if date has bookings before closing calendar
                  if (_isDateBooked(selectedDay)) {
                    Navigator.pop(context);
                    _showDateBookingInfo(selectedDay);
                  } else {
                    Navigator.pop(context);
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade200,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Today',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Selected',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Has bookings',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDateBooked(DateTime date) {
    return _bookedDates.any((bookedDate) => 
      bookedDate.year == date.year &&
      bookedDate.month == date.month &&
      bookedDate.day == date.day
    );
  }

  List<Map<String, dynamic>> _getBookingsForDate(DateTime date) {
    return _bookedSlots.where((slot) {
      final bookingDate = DateTime.parse(slot['booking_date']);
      return bookingDate.year == date.year &&
             bookingDate.month == date.month &&
             bookingDate.day == date.day &&
             (slot['status'] == 'pending' || 
              slot['status'] == 'accepted' || 
              slot['status'] == 'in_progress');
    }).toList();
  }

  bool _isTimeSlotAvailable(TimeOfDay time, int hours) {
    if (_selectedDate == null) return true;
    
    final bookings = _getBookingsForDate(_selectedDate!);
    if (bookings.isEmpty) return true;
    
    final selectedStart = time.hour + (time.minute / 60);
    final selectedEnd = selectedStart + hours;
    
    for (var booking in bookings) {
      final bookingTime = booking['booking_time'] as String;
      final timeParts = bookingTime.split(':');
      final bookingHour = int.parse(timeParts[0]);
      final bookingMinute = int.parse(timeParts[1].split(' ')[0]);
      final isPM = bookingTime.contains('PM') && bookingHour != 12;
      final is12AM = bookingTime.contains('AM') && bookingHour == 12;
      
      final bookingStart = (isPM ? bookingHour + 12 : (is12AM ? 0 : bookingHour)) + (bookingMinute / 60);
      final bookingEnd = bookingStart + (booking['duration_hours'] as num);
      
      // Check for overlap
      if ((selectedStart >= bookingStart && selectedStart < bookingEnd) ||
          (selectedEnd > bookingStart && selectedEnd <= bookingEnd) ||
          (selectedStart <= bookingStart && selectedEnd >= bookingEnd)) {
        return false;
      }
    }
    
    return true;
  }

  void _showDateBookingInfo(DateTime date) {
    final bookings = _getBookingsForDate(date);
    logger.debug('BookingScreen: Showing ${bookings.length} bookings for ${DateFormat('yyyy-MM-dd').format(date)}');
    for (var booking in bookings) {
      logger.debug('  - ${booking['booking_time']} (${booking['duration_hours']}h)');
    }
    
    if (bookings.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Booked Time Slots',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Already booked times:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...bookings.map((booking) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${booking['booking_time']} (${booking['duration_hours']}h)',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Text(
                  'You can still book other available time slots on this date.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  double _calculateTotal() {
    final hourlyRate = widget.provider['hourly_rate'] as num? ?? 0;
    return hourlyRate.toDouble() * _selectedHours;
  }

  bool _canSubmit() {
    return _selectedDate != null && 
           _selectedTime != null;
  }

  Future<void> _submitBooking() async {
    if (!_canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if selected time slot is available
    if (!_isTimeSlotAvailable(_selectedTime!, _selectedHours)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Time Slot Unavailable'),
            ],
          ),
          content: const Text(
            'This time slot overlaps with an existing booking. Please select a different time or date.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Validate required fields
    if (_jobLocationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter job location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_jobInstructionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter job instructions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final profile = widget.provider['profiles'] as Map<String, dynamic>;
      final providerId = profile['id'] as String;
      final hourlyRate = widget.provider['hourly_rate'] as num;

      final bookingService = BookingService();
      await bookingService.createBooking(
        providerId: providerId,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTime!.format(context),
        durationHours: _selectedHours,
        hourlyRate: hourlyRate.toDouble(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        jobLocation: _jobLocationController.text.isEmpty ? null : _jobLocationController.text,
        jobInstructions: _jobInstructionsController.text.isEmpty ? null : _jobInstructionsController.text,
        clientBudget: _budgetController.text.isEmpty ? null : double.tryParse(_budgetController.text),
        secondaryContact: _secondaryContactController.text.isEmpty ? null : _secondaryContactController.text,
      );

      if (!mounted) return;

      // Close loading
      Navigator.of(context).pop();

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to provider detail
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      // Close loading
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.provider['profiles'] as Map<String, dynamic>;
    final hourlyRate = widget.provider['hourly_rate'] as num? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.teal.shade50,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.teal.shade100,
                          backgroundImage: profile['avatar_url'] != null
                              ? NetworkImage(profile['avatar_url'])
                              : null,
                          child: profile['avatar_url'] == null
                              ? Text(
                                  (profile['full_name'] as String?)
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'P',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile['full_name'] ?? 'Provider',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'N\$${hourlyRate.toStringAsFixed(2)}/hr',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedDate != null ? Colors.grey.shade800 : null,
                              border: Border.all(color: _selectedDate != null ? Colors.teal : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: _selectedDate != null ? Colors.white : Colors.teal,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Choose a date'
                                      : DateFormat('EEEE, MMMM d, yyyy')
                                          .format(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDate == null
                                        ? Colors.grey.shade600
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedTime != null ? Colors.grey.shade800 : null,
                              border: Border.all(color: _selectedTime != null ? Colors.teal : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: _selectedTime != null ? Colors.white : Colors.teal,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedTime == null
                                      ? 'Choose a time'
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedTime == null
                                        ? Colors.grey.shade600
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Availability indicator
                  if (_selectedDate != null && _selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isTimeSlotAvailable(_selectedTime!, _selectedHours)
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isTimeSlotAvailable(_selectedTime!, _selectedHours)
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isTimeSlotAvailable(_selectedTime!, _selectedHours)
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _isTimeSlotAvailable(_selectedTime!, _selectedHours)
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isTimeSlotAvailable(_selectedTime!, _selectedHours)
                                    ? 'Time slot is available!'
                                    : 'Time slot overlaps with existing booking',
                                style: TextStyle(
                                  color: _isTimeSlotAvailable(_selectedTime!, _selectedHours)
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Duration Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration (hours)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _selectedHours > 1
                                  ? () {
                                      setState(() {
                                        _selectedHours--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.teal,
                              iconSize: 32,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.teal),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_selectedHours',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _selectedHours < 8
                                  ? () {
                                      setState(() {
                                        _selectedHours++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.teal,
                              iconSize: 32,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _selectedHours == 1 ? 'hour' : 'hours',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Job Location
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Job Location *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            final locations = [
                              'Windhoek, Namibia',
                              'Swakopmund, Namibia',
                              'Walvis Bay, Namibia',
                              'Oshakati, Namibia',
                              'Rundu, Namibia',
                              'Katima Mulilo, Namibia',
                              'Otjiwarongo, Namibia',
                              'Grootfontein, Namibia',
                              'Tsumeb, Namibia',
                              'Gobabis, Namibia',
                              'Rehoboth, Namibia',
                              'Keetmanshoop, Namibia',
                              'Okahandja, Namibia',
                              'Mariental, Namibia',
                              'Lüderitz, Namibia',
                              'Outapi, Namibia',
                              'Ondangwa, Namibia',
                              'Oranjemund, Namibia',
                            ];
                            return locations.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _jobLocationController.text = selection;
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            controller.text = _jobLocationController.text;
                            controller.addListener(() {
                              _jobLocationController.text = controller.text;
                            });
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Enter the address where the job will be performed',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                                ),
                              ),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Job Instructions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Job Instructions *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _jobInstructionsController,
                          maxLines: 4,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Describe the work to be done in detail...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.teal, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Client Budget
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Budget (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your budget in N\$',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.attach_money, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.teal, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secondary Contact
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secondary Contact (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _secondaryContactController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Alternative phone number',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.teal, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Notes (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Any other details...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.teal, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Price Summary
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hourly Rate',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'N\$${hourlyRate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '$_selectedHours ${_selectedHours == 1 ? 'hour' : 'hours'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'N\$${_calculateTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80), // Space for button
                ],
              ),
            ),
          ),

          // Bottom Submit Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit() ? _submitBooking : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade700,
                      ),
                      child: Text(
                        _canSubmit()
                            ? 'Confirm Booking - N\$${_calculateTotal().toStringAsFixed(2)}'
                            : 'Select Date & Time',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
