import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/provider_provider.dart';
import '../../../core/providers/auth_provider.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _showCustomInput = false;
  String _rateType = 'base';

  @override
  void dispose() {
    _descriptionController.dispose();
    _basePriceController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _handleAddService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if either category is selected or custom category is provided
    if (!_showCustomInput && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a category', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
      return;
    }
    
    if (_showCustomInput && _customCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter custom category', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
      return;
    }

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String categoryId;
      
      // If custom category, create it first
      if (_showCustomInput) {
        categoryId = await ref
            .read(providerServiceProvider)
            .createCustomCategory(_customCategoryController.text.trim());
      } else {
        categoryId = _selectedCategoryId!;
      }
      
      // Determine rate based on rate type - exactly like registration screen
      double? selectedPrice;
      if (_rateType == 'hourly' && _hourlyRateController.text.trim().isNotEmpty) {
        selectedPrice = double.tryParse(_hourlyRateController.text);
      } else if (_rateType == 'daily' && _dailyRateController.text.trim().isNotEmpty) {
        final dailyRate = double.tryParse(_dailyRateController.text);
        if (dailyRate != null) {
          selectedPrice = dailyRate; // Store daily rate as-is
        }
      } else if (_rateType == 'base' && _basePriceController.text.trim().isNotEmpty) {
        selectedPrice = double.tryParse(_basePriceController.text);
      }

      if (selectedPrice == null || selectedPrice <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid price', style: TextStyle(fontSize: 13)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Add service - exactly like registration screen
      await ref.read(providerRegistrationProvider.notifier).addService(
            providerId: user.id,
            categoryId: categoryId,
            description: _descriptionController.text.trim(),
            basePrice: selectedPrice,
            rateType: _rateType,
          );

      print('✅ [ADD SERVICE] Service added successfully for user: ${user.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service added!', style: TextStyle(fontSize: 13)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
        
        // Invalidate providers to force refresh
        ref.invalidate(userProfileProvider);
        ref.invalidate(providerServicesProvider(user.id));
        ref.invalidate(providerProfileProvider(user.id));
        
        print('✅ [ADD SERVICE] Providers invalidated');
        
        // Navigate to dashboard - autoDispose will ensure fresh fetch
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted) {
          context.go('/provider-dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e', style: const TextStyle(fontSize: 13)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final activeCategories = categories.where((c) => c.isActive).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Service Category Dropdown
                  if (!_showCustomInput)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Service Category',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          isExpanded: true,
                          menuMaxHeight: 300,
                          items: activeCategories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Text(
                                _capitalizeWords(category.name),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _selectedCategoryId = value);
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Select a service category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showCustomInput = true;
                              _selectedCategoryId = null;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Custom Category'),
                        ),
                      ],
                    ),
                  
                  // Custom Category Input
                  if (_showCustomInput)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _customCategoryController,
                          decoration: InputDecoration(
                            labelText: 'Custom Category Name',
                            hintText: 'e.g., Software Testing',
                            prefixIcon: const Icon(Icons.edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a category name';
                            }
                            if (value.length < 3) {
                              return 'Category name too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showCustomInput = false;
                              _customCategoryController.clear();
                            });
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Categories'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Description Field (moved before rate type to match registration screen order)
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Service Description',
                      hintText: 'Describe what you offer for this service',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Rate Type Selection - exactly like registration screen
                  Text(
                    'Rate Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Base Rate'),
                        selected: _rateType == 'base',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _rateType = 'base';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Hourly Rate'),
                        selected: _rateType == 'hourly',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _rateType = 'hourly';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Daily Rate'),
                        selected: _rateType == 'daily',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _rateType = 'daily';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rate Input based on selection - exactly like registration screen
                  if (_rateType == 'base')
                    TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Base Rate (R)',
                        hintText: 'Enter your base rate',
                        border: OutlineInputBorder(),
                        prefixText: 'R ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter base rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                  if (_rateType == 'hourly')
                    TextFormField(
                      controller: _hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Rate (R)',
                        hintText: 'Enter your hourly rate',
                        border: OutlineInputBorder(),
                        prefixText: 'R ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter hourly rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                  if (_rateType == 'daily')
                    TextFormField(
                      controller: _dailyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Daily Rate (R)',
                        hintText: 'Enter your daily rate',
                        border: OutlineInputBorder(),
                        prefixText: 'R ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter daily rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                  const SizedBox(height: 24),

                  // Add Service Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAddService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading categories: $error'),
        ),
      ),
    );
  }
}
