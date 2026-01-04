import 'package:flutter/material.dart';

class JobCompletionDialog extends StatefulWidget {
  const JobCompletionDialog({super.key});

  @override
  State<JobCompletionDialog> createState() => _JobCompletionDialogState();
}

class _JobCompletionDialogState extends State<JobCompletionDialog> with SingleTickerProviderStateMixin {
  // Checklist items
  bool _allWorkCompleted = false;
  bool _clientSatisfied = false;
  bool _areaCleanedUp = false;
  bool _noIssuesEncountered = false;
  bool _clientPresent = false;
  
  // Optional feedback
  final _feedbackController = TextEditingController();
  
  // Client rating (provider rates client)
  double _clientRating = 0;
  final _clientReviewController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _clientReviewController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Job',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Confirm job completion details',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Completion Checklist
                      _buildSectionTitle('Job Completion Checklist'),
                      const SizedBox(height: 12),
                      _buildCheckItem(
                        'All work completed as requested',
                        _allWorkCompleted,
                        (value) => setState(() => _allWorkCompleted = value ?? false),
                      ),
                      _buildCheckItem(
                        'Client satisfied with the work',
                        _clientSatisfied,
                        (value) => setState(() => _clientSatisfied = value ?? false),
                      ),
                      _buildCheckItem(
                        'Work area cleaned and tidied',
                        _areaCleanedUp,
                        (value) => setState(() => _areaCleanedUp = value ?? false),
                      ),
                      _buildCheckItem(
                        'No major issues encountered',
                        _noIssuesEncountered,
                        (value) => setState(() => _noIssuesEncountered = value ?? false),
                      ),
                      _buildCheckItem(
                        'Client was present during completion',
                        _clientPresent,
                        (value) => setState(() => _clientPresent = value ?? false),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Optional Feedback
                      _buildSectionTitle('Additional Notes (Optional)'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any additional comments or feedback...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Rate Client Section
                      _buildSectionTitle('Rate Your Client (Optional)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Communication & Cooperation:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _clientRating = index + 1.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  index < _clientRating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _clientReviewController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Review your experience with this client...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _canComplete() ? () {
                        final Map<String, String?> result = {
                          'workCompleted': _buildCompletionSummary(),
                          'completionNotes': _feedbackController.text.trim().isEmpty 
                              ? null 
                              : _feedbackController.text.trim(),
                          'clientRating': _clientRating > 0 ? _clientRating.toString() : null,
                          'clientReview': _clientReviewController.text.trim().isEmpty 
                              ? null 
                              : _clientReviewController.text.trim(),
                        };
                        Navigator.pop(context, result);
                      } : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildCheckItem(String label, bool value, Function(bool?) onChanged) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.green.shade300 : Colors.grey.shade300,
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
            color: value ? Colors.green.shade900 : Colors.black87,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green.shade700,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  bool _canComplete() {
    // At least the main work completion checkbox must be checked
    return _allWorkCompleted;
  }
  
  String _buildCompletionSummary() {
    List<String> completed = [];
    if (_allWorkCompleted) completed.add('✅ All work completed');
    if (_clientSatisfied) completed.add('✅ Client satisfied');
    if (_areaCleanedUp) completed.add('✅ Area cleaned up');
    if (_noIssuesEncountered) completed.add('✅ No issues encountered');
    if (_clientPresent) completed.add('✅ Client was present');
    
    List<String> notCompleted = [];
    if (!_clientSatisfied) notCompleted.add('❌ Client satisfaction not confirmed');
    if (!_areaCleanedUp) notCompleted.add('❌ Area cleanup not confirmed');
    if (_noIssuesEncountered == false) notCompleted.add('❌ Issues were encountered');
    if (!_clientPresent) notCompleted.add('❌ Client was not present');
    
    return [...completed, ...notCompleted].join('\n');
  }
}
