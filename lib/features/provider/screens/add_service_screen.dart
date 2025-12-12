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
  final _customCategoryController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _showCustomInput = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _basePriceController.dispose();
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

    final user = ref.read(currentUserProvider).value;
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

    // Check for duplicate service
    final existingServicesAsync = ref.read(providerServicesProvider(user.id));
    await existingServicesAsync.when(
      data: (services) async {
        // Only check duplicates if selecting from existing categories
        if (!_showCustomInput) {
          final isDuplicate = services.any((service) => 
            service['service_category_id'] == _selectedCategoryId
          );
          
          if (isDuplicate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service already added', style: TextStyle(fontSize: 13)),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
            return;
          }
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
          
          await ref.read(providerRegistrationProvider.notifier).addService(
                providerId: user.id,
                categoryId: categoryId,
                description: _descriptionController.text.trim(),
                basePrice: double.parse(_basePriceController.text),
              );

          // Invalidate the services provider to refresh the dashboard
          print('✅ Service added! Invalidating providers for user: ${user.id}');
          ref.invalidate(providerServicesProvider(user.id));
          ref.invalidate(providerProfileProvider(user.id));
          ref.invalidate(serviceCategoriesProvider); // Refresh categories too

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
            
            // Wait a moment then pop to allow providers to invalidate
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) context.pop();
            });
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
      },
      loading: () async {
        // If still loading, proceed without duplicate check
        setState(() => _isLoading = true);
        try {
          await ref.read(providerRegistrationProvider.notifier).addService(
                providerId: user.id,
                categoryId: _selectedCategoryId!,
                description: _descriptionController.text.trim(),
                basePrice: double.parse(_basePriceController.text),
              );

          ref.invalidate(providerServicesProvider);

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
            context.pop();
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
      },
      error: (error, stack) async {
        // On error, proceed without duplicate check
        setState(() => _isLoading = true);
        try {
          await ref.read(providerRegistrationProvider.notifier).addService(
                providerId: user.id,
                categoryId: _selectedCategoryId!,
                description: _descriptionController.text.trim(),
                basePrice: double.parse(_basePriceController.text),
              );

          ref.invalidate(providerServicesProvider);

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
            context.pop();
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
      },
    );
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
                          menuMaxHeight: 300, // Makes dropdown scrollable
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
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Service Description',
                      hintText: 'Describe what you offer for this service',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a description';
                      }
                      if (value.length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Base Price Field
                  TextFormField(
                    controller: _basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Base Price (\$)',
                      hintText: 'Enter your rate for this service',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a base price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Enter a valid price';
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
