import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionRequiredScreen extends StatefulWidget {
  const SubscriptionRequiredScreen({super.key});

  @override
  State<SubscriptionRequiredScreen> createState() => _SubscriptionRequiredScreenState();
}

class _SubscriptionRequiredScreenState extends State<SubscriptionRequiredScreen> {
  int _selectedPlan = 0; // 0=Free, 1=Basic, 2=Pro, 3=Unlimited
  bool _isYearly = true; // true=Yearly, false=Monthly

  // Monthly prices
  final Map<int, int> _monthlyPrices = {
    1: 10,  // Basic
    2: 20,  // Pro
    3: 35,  // Unlimited
  };

  // Yearly prices (with discount)
  final Map<int, int> _yearlyPrices = {
    1: 99,   // Basic (normally 120, save 21)
    2: 199,  // Pro (normally 240, save 41)
    3: 349,  // Unlimited (normally 420, save 71)
  };

  String _getPrice(int index) {
    if (index == 0) return 'N\$0';
    if (_isYearly) {
      return 'N\$${_yearlyPrices[index]}';
    } else {
      return 'N\$${_monthlyPrices[index]}';
    }
  }

  String _getPeriod(int index) {
    if (index == 0) return 'Forever';
    return _isYearly ? 'per year' : 'per month';
  }

  int _getSavings(int index) {
    if (index == 0 || !_isYearly) return 0;
    return (_monthlyPrices[index]! * 12) - _yearlyPrices[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Select the plan that fits your needs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Payment Period Toggle
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isYearly = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isYearly ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: !_isYearly
                                ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              fontWeight: !_isYearly ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isYearly = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isYearly ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _isYearly
                                ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Yearly',
                                style: TextStyle(
                                  fontWeight: _isYearly ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SAVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Free Plan
              _buildPlanCard(
                index: 0,
                title: 'Free',
                price: 'N\$0',
                period: 'Forever',
                serviceLimit: '1 service only',
                features: [
                  'Register 1 service',
                  'Basic profile visibility',
                  'Client messaging',
                  'Booking management',
                  'Portfolio (photos only)',
                ],
                color: Colors.grey,
                isRecommended: false,
              ),
              const SizedBox(height: 16),

              // Basic Plan
              _buildPlanCard(
                index: 1,
                title: 'Basic',
                price: _getPrice(1),
                period: _getPeriod(1),
                savings: _getSavings(1),
                serviceLimit: 'Up to 5 services',
                features: [
                  'Everything in Free',
                  'Register up to 5 services',
                  'Enhanced profile visibility',
                  'Portfolio (photos & videos)',
                  'Priority support',
                ],
                color: Colors.blue,
                isRecommended: false,
              ),
              const SizedBox(height: 16),

              // Pro Plan
              _buildPlanCard(
                index: 2,
                title: 'Pro',
                price: _getPrice(2),
                period: _getPeriod(2),
                savings: _getSavings(2),
                serviceLimit: 'Up to 10 services',
                features: [
                  'Everything in Basic',
                  'Register up to 10 services',
                  'Featured profile badge',
                  'Advanced analytics',
                  'Custom branding',
                ],
                color: Colors.purple,
                isRecommended: true,
              ),
              const SizedBox(height: 16),

              // Unlimited Plan
              _buildPlanCard(
                index: 3,
                title: 'Unlimited',
                price: _getPrice(3),
                period: _getPeriod(3),
                savings: _getSavings(3),
                serviceLimit: 'Unlimited services',
                features: [
                  'Everything in Pro',
                  'Unlimited services',
                  'Top search ranking',
                  'Dedicated account manager',
                  'API access',
                ],
                color: Colors.teal,
                isRecommended: false,
              ),

              const SizedBox(height: 32),

              // Action button
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedPlan == 0
                        ? () {
                            context.pop();
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment integration coming soon!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selectedPlan == 0 ? 'Continue with Free Plan' : 'Subscribe Now',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    int savings = 0,
    required String serviceLimit,
    required List<String> features,
    required Color color,
    required bool isRecommended,
  }) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Stack(
          children: [
            if (isRecommended)
              Positioned(
                top: 0,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 16, color: color)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (savings > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'Save N\$$savings/year',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    serviceLimit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
