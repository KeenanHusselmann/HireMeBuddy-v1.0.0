import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/provider_provider.dart';
import '../../../shared/widgets/app_logo.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends ConsumerState<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _skillController = TextEditingController();
  
  final List<String> _skills = [];
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _bioController.dispose();
    _hourlyRateController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  Future<void> _handleRegistration() async {
    print('ProviderRegistration: Starting registration process');
    
    if (!_formKey.currentState!.validate()) {
      print('ProviderRegistration: Form validation failed');
      return;
    }

    if (_skills.isEmpty) {
      print('ProviderRegistration: No skills added');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      print('ProviderRegistration: No categories selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service category')),
      );
      return;
    }

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    
    if (user == null) {
      print('ProviderRegistration: User not found');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please login again.')),
        );
      }
      return;
    }

    print('ProviderRegistration: User ID: ${user.id}');
    print('ProviderRegistration: User email: ${user.email}');
    print('ProviderRegistration: Bio: ${_bioController.text.trim()}');
    print('ProviderRegistration: Skills: $_skills');
    print('ProviderRegistration: Hourly rate: ${_hourlyRateController.text}');
    print('ProviderRegistration: Selected categories: $_selectedCategories');

    await ref.read(providerRegistrationProvider.notifier).registerProvider(
          userId: user.id,
          bio: _bioController.text.trim(),
          skills: _skills,
          hourlyRate: double.parse(_hourlyRateController.text),
        );

    final state = ref.read(providerRegistrationProvider);

    if (state.error != null) {
      print('ProviderRegistration: Registration error: ${state.error}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${state.error}', style: const TextStyle(fontSize: 13)),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      }
    } else if (state.profile != null) {
      print('ProviderRegistration: Profile created, adding services...');
      // Add services for selected categories
      for (final categoryId in _selectedCategories) {
        print('ProviderRegistration: Adding category: $categoryId');
        await ref.read(providerRegistrationProvider.notifier).addService(
              providerId: user.id,
              categoryId: categoryId,
              description: _bioController.text.trim(),
              basePrice: double.parse(_hourlyRateController.text),
            );
      }

      print('ProviderRegistration: All services added, registration complete!');
      if (mounted) {
        // Invalidate caches to force refresh with new data
        ref.invalidate(userProfileProvider);
        ref.invalidate(providerServicesProvider(user.id));
        ref.invalidate(providerProfileProvider(user.id));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!', style: TextStyle(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
        
        // Longer delay to ensure all data is committed and refreshed
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          print('ProviderRegistration: Navigating to dashboard...');
          context.go('/provider-dashboard');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final registrationState = ref.watch(providerRegistrationProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Become a Service Provider'),
          ),
          body: Column(
            children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const AppLogo(width: 100),
                    const SizedBox(height: 16),
                    const Text(
                      'Register as Provider',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell clients about yourself and your experience',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your bio';
                        }
                        if (value.length < 20) {
                          return 'Bio must be at least 20 characters';
                        }
                        return null;
                      },
                      enabled: !registrationState.isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Hourly Rate Field
                    TextFormField(
                      controller: _hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Rate (\$)',
                        hintText: 'Enter your hourly rate',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your hourly rate';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null || rate <= 0) {
                          return 'Please enter a valid rate';
                        }
                        return null;
                      },
                      enabled: !registrationState.isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Skills Section
                    const Text(
                      'Skills',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _skillController,
                            decoration: const InputDecoration(
                              hintText: 'Add a skill',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onSubmitted: (_) => _addSkill(),
                            enabled: !registrationState.isLoading,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: registrationState.isLoading ? null : _addSkill,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _skills
                          .asMap()
                          .entries
                          .map(
                            (entry) => Chip(
                              label: Text(entry.value),
                              onDeleted: registrationState.isLoading
                                  ? null
                                  : () => _removeSkill(entry.key),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),

                    // Service Categories Section
                    const Text(
                      'Service Categories',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      data: (categories) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final isSelected = _selectedCategories.contains(category.id);
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: registrationState.isLoading
                                ? null
                                : (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCategories.add(category.id);
                                      } else {
                                        _selectedCategories.remove(category.id);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Error loading categories: $error'),
                    ),
                    const SizedBox(height: 16),

                    // Register Button
                    ElevatedButton(
                      onPressed: registrationState.isLoading ? null : _handleRegistration,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: registrationState.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Register as Provider',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.teal,
              child: const Text(
                '© 2025 HireMeBuddy. All rights reserved.',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
        ),
        // Loading overlay
        if (registrationState.isLoading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Setting up your profile...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we create your provider account',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
