import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/booking.dart';
import 'add_review_screen.dart';
import 'my_bookings_screen.dart' show bookingPaymentStatusProvider, clientBookingsProvider;

class PaymentScreen extends ConsumerStatefulWidget {
  final Booking booking;
  final String providerName;
  final String? providerPhone;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.providerName,
    this.providerPhone,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String _selectedMethod = 'cash'; // cash, eft, mobile

  // HireMeBuddy service fee percentage
  static const double serviceFeePercentage = 0.10; // 10%

  double get serviceFee => widget.booking.totalPrice * serviceFeePercentage;
  double get totalAmount => widget.booking.totalPrice + serviceFee;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Update booking updated_at timestamp
      await supabase.from('bookings').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.booking.id);

      // Record payment transaction
      await supabase.from('payments').insert({
        'booking_id': widget.booking.id,
        'amount': totalAmount,
        'currency': 'NAD',
        'payment_method': _selectedMethod,
        'status': 'paid',
      });

      // Notify provider of payment via RPC
      try {
        await supabase.rpc(
          'send_notification',
          params: {
            'p_user_id': widget.booking.providerId,
            'p_title': 'Payment Received',
            'p_body': 'Payment of N\$${totalAmount.toStringAsFixed(2)} has been received for your completed job.',
            'p_type': 'payment_received',
          },
        );
      } catch (e) {
        // Fallback to direct insert if RPC fails
        await supabase.from('notifications').insert({
          'user_id': widget.booking.providerId,
          'title': 'Payment Received',
          'body': 'Payment of N\$${totalAmount.toStringAsFixed(2)} has been received for your completed job.',
          'type': 'payment',
        });
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidate payment status provider immediately after payment is recorded
        ref.invalidate(bookingPaymentStatusProvider(widget.booking.id));
        ref.invalidate(clientBookingsProvider);

        // Navigate to review screen (optional)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddReviewScreen(
              bookingId: widget.booking.id,
              providerId: widget.booking.providerId,
              providerName: widget.providerName,
            ),
          ),
        );

        // Always return true to indicate payment succeeded,
        // even if the user didn't submit a written review
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              // Payment header
              const Icon(
                Icons.payment,
                size: 64,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete Payment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Payment to ${widget.providerName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Payment breakdown card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Service amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Service Amount',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'N\$${widget.booking.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Service fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HireMeBuddy Service Fee',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '(${(serviceFeePercentage * 100).toInt()}%)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'N\$${serviceFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 2),
                      const SizedBox(height: 16),

                      // Total amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'N\$${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 24),

              // Payment method selection
              const Text(
                'Choose a payment method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedMethod = 'cash');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _selectedMethod == 'cash' ? Colors.teal.shade50 : null,
                        side: BorderSide(
                          color: _selectedMethod == 'cash'
                              ? Colors.teal
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: const Text('Cash'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedMethod = 'eft');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _selectedMethod == 'eft' ? Colors.teal.shade50 : null,
                        side: BorderSide(
                          color: _selectedMethod == 'eft'
                              ? Colors.teal
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: const Text('EFT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedMethod = 'mobile');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _selectedMethod == 'mobile' ? Colors.teal.shade50 : null,
                        side: BorderSide(
                          color: _selectedMethod == 'mobile'
                              ? Colors.teal
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: const Text('Mobile'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Method-specific instructions
              if (_selectedMethod == 'cash') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Cash Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '- Only pay the provider after the job is completed.\n'
                        '- Meet in a safe, public place when possible.\n'
                        '- Never hand over cash if you feel unsafe.\n'
                        '- After paying, mark the provider as paid in the app so we can track the job.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedMethod == 'eft') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EFT Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can pay the provider via EFT using their banking details.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final supabase = Supabase.instance.client;
                              
                              // Get client's profile ID
                              final user = supabase.auth.currentUser;
                              if (user == null) {
                                throw Exception('User not authenticated');
                              }
                              
                              final clientProfile = await supabase
                                  .from('profiles')
                                  .select('id')
                                  .eq('user_id', user.id)
                                  .single();
                              
                              final clientProfileId = clientProfile['id'] as String;
                              
                              // Create a chat message so it appears in messages
                              final messageContent = 'Hi! I need your banking details for job ${widget.booking.jobNumber} to proceed with payment. Could you please share them?';
                              
                              await supabase.from('chat_messages').insert({
                                'sender_id': clientProfileId,
                                'receiver_id': widget.booking.providerId,
                                'content': messageContent,
                                'read': false,
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request sent to provider. Check your messages for their response.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send request: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.account_balance),
                          label: const Text('Request Banking Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedMethod == 'mobile') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mobile Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.booking.secondaryContact != null &&
                                widget.booking.secondaryContact!.isNotEmpty
                            ? 'Use this mobile number to send payment:\n${widget.booking.secondaryContact}'
                            : 'Use the provider\'s registered mobile number in the booking details to send payment.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Pay button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
