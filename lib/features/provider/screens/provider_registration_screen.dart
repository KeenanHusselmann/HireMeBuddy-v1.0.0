import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/provider_provider.dart';
import 'id_card_camera_screen.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends ConsumerState<ProviderRegistrationScreen> {
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(), // Step 1: Provider Details
    GlobalKey<FormState>(), // Step 2: Identification
    GlobalKey<FormState>(), // Step 3: Service Photos
    GlobalKey<FormState>(), // Step 4: Terms
  ];

  // Step 1: Provider Details
  final _bioController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _skillController = TextEditingController();
  String _rateType = 'hourly';
  final _baseRateController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _weeklyRateController = TextEditingController();
  final List<String> _skills = [];
  final Set<String> _selectedCategories = {};

  // Step 2: Identification Photos
  File? _idFrontImage;
  File? _idBackImage;
  File? _headshotImage;

  // Step 3: Service Photos
  final List<File> _servicePhotos = [];

  // Step 4: Terms and Conditions
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  final ImagePicker _picker = ImagePicker();

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _bioController.dispose();
    _yearsOfExperienceController.dispose();
    _skillController.dispose();
    _baseRateController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _weeklyRateController.dispose();
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

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      // Determine the title based on type
      String title = '';
      switch (type) {
        case 'id_front':
          title = 'ID Document - Front';
          break;
        case 'id_back':
          title = 'ID Document - Back';
          break;
        case 'headshot':
          title = 'Headshot Photo';
          break;
      }

      // Navigate to custom camera screen with frame overlay
      final File? capturedImage = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => IdCardCameraScreen(title: title),
        ),
      );

      if (capturedImage != null) {
        setState(() {
          switch (type) {
            case 'id_front':
              _idFrontImage = capturedImage;
              break;
            case 'id_back':
              _idBackImage = capturedImage;
              break;
            case 'headshot':
              _headshotImage = capturedImage;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickServicePhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (images.isNotEmpty) {
        setState(() {
          _servicePhotos.addAll(images.map((e) => File(e.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  // Compress image to portrait smaller scale
  Future<Uint8List> _compressImage(File imageFile) async {
    // Read the image file
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) {
      return bytes;
    }

    // Resize to portrait orientation (max width 600px, maintain aspect ratio)
    const maxWidth = 600;
    if (image.width > maxWidth) {
      final height = (image.height * maxWidth / image.width).round();
      image = img.copyResize(image, width: maxWidth, height: height);
    }

    // Compress as JPEG with 75% quality
    final compressedBytes = img.encodeJpg(image, quality: 75);
    return Uint8List.fromList(compressedBytes);
  }

  void _removeServicePhoto(int index) {
    setState(() {
      _servicePhotos.removeAt(index);
    });
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0: // Provider Details
        if (!(_formKeys[0].currentState?.validate() ?? false)) {
          return false;
        }
        if (_skills.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one skill')),
          );
          return false;
        }
        if (_selectedCategories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one service category')),
          );
          return false;
        }
        // Validate rate based on rate type
        if (_rateType == 'base' && _baseRateController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter base rate')),
          );
          return false;
        }
        if (_rateType == 'hourly' && _hourlyRateController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter hourly rate')),
          );
          return false;
        }
        if (_rateType == 'daily' && _dailyRateController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter daily rate')),
          );
          return false;
        }
        return true;
      case 1: // Identification
        if (_idFrontImage == null || _idBackImage == null || _headshotImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload all required identification photos')),
          );
          return false;
        }
        return true;
      case 2: // Service Photos
        if (_servicePhotos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload at least one service photo')),
          );
          return false;
        }
        return true;
      case 3: // Terms
        if (!_agreedToTerms || !_agreedToPrivacy) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please agree to terms and conditions and privacy policy')),
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
      } else {
        _handleRegistration();
      }
    }
  }

  // ignore: unused_element
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _showLoadingDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => const _GlassmorphismLoadingDialog(),
    );
  }

  void _dismissLoadingDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _handleRegistration() async {
    if (!_validateStep(_currentStep)) return;

    // Get the Supabase Auth user
    final user = await ref.read(currentUserProvider.future);

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please login again.')),
        );
      }
      return;
    }

    // Get the user profile with firstName/lastName
    final profile = await ref.read(userProfileProvider.future);

    if (profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found. Please try again.')),
        );
      }
      return;
    }

    await _showLoadingDialog();

    try {
      // Upload images to Supabase storage
      final supabase = Supabase.instance.client;
      String? idFrontUrl;
      String? idBackUrl;
      String? headshotUrl;
      List<String> servicePhotoUrls = [];

      try {
        // Upload ID Front
        if (_idFrontImage != null) {
          final compressedImage = await _compressImage(_idFrontImage!);
          final fileName = '${user.id}_id_front_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('verification-documents')
              .uploadBinary(fileName, compressedImage);
          idFrontUrl = supabase.storage.from('verification-documents').getPublicUrl(fileName);
        }

        // Upload ID Back
        if (_idBackImage != null) {
          final compressedImage = await _compressImage(_idBackImage!);
          final fileName = '${user.id}_id_back_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('verification-documents')
              .uploadBinary(fileName, compressedImage);
          idBackUrl = supabase.storage.from('verification-documents').getPublicUrl(fileName);
        }

        // Upload Headshot
        if (_headshotImage != null) {
          final compressedImage = await _compressImage(_headshotImage!);
          final fileName = '${user.id}_headshot_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('verification-documents')
              .uploadBinary(fileName, compressedImage);
          headshotUrl = supabase.storage.from('verification-documents').getPublicUrl(fileName);
        }

        // Upload Service Photos
        for (int i = 0; i < _servicePhotos.length; i++) {
          final compressedImage = await _compressImage(_servicePhotos[i]);
          final fileName = '${user.id}_service_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('verification-documents')
              .uploadBinary(fileName, compressedImage);
          final url = supabase.storage.from('verification-documents').getPublicUrl(fileName);
          servicePhotoUrls.add(url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading images: $e')),
          );
        }
        return;
      }

      // Determine rate based on rate type
      double? hourlyRate;
      if (_rateType == 'hourly' && _hourlyRateController.text.trim().isNotEmpty) {
        hourlyRate = double.tryParse(_hourlyRateController.text);
      } else if (_rateType == 'daily' && _dailyRateController.text.trim().isNotEmpty) {
        final dailyRate = double.tryParse(_dailyRateController.text);
        if (dailyRate != null) {
          hourlyRate = dailyRate / 8; // Convert to hourly
        }
      } else if (_rateType == 'base' && _baseRateController.text.trim().isNotEmpty) {
        hourlyRate = double.tryParse(_baseRateController.text);
      }

      await ref.read(providerRegistrationProvider.notifier).registerProvider(
            userId: user.id,
            firstName: profile.firstName ?? '',
            lastName: profile.lastName ?? '',
            bio: _bioController.text.trim(),
            skills: _skills,
            hourlyRate: hourlyRate ?? 0.0,
          );

      final state = ref.read(providerRegistrationProvider);

      if (state.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${state.error}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (state.profile != null) {
        // Update provider profile with document URLs
        await supabase.from('provider_profiles').update({
          'id_front_url': idFrontUrl,
          'id_back_url': idBackUrl,
          'headshot_url': headshotUrl,
          'service_photos_urls': servicePhotoUrls,
          'documents_status': 'pending',
        }).eq('id', user.id);

        // Add services for selected categories
        for (final categoryId in _selectedCategories) {
      await ref.read(providerRegistrationProvider.notifier).addService(
            providerId: user.id,
            categoryId: categoryId,
            description: _bioController.text.trim(),
            basePrice: hourlyRate ?? 0.0,
            rateType: _rateType,
          );
        }

        if (mounted) {
          ref.invalidate(userProfileProvider);
          ref.invalidate(providerServicesProvider(user.id));
          ref.invalidate(providerProfileProvider(user.id));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Documents sent for admin review.')),
          );
          
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (mounted) {
            context.go('/provider-dashboard');
          }
        }
      }
    } finally {
      _dismissLoadingDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerRegistrationProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Registration'),
        elevation: 0,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Stack(
            children: [
              Column(
                children: [
                  // Progress Indicator
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index < 3 ? 8 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: _buildStepContent(),
                  ),
                  // Navigation Buttons
                  Container(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 16.0,
                      bottom: 24.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep < 3 ? 'Next' : 'Complete Registration',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProviderDetailsStep();
      case 1:
        return _buildIdentificationStep();
      case 2:
        return _buildServicePhotosStep();
      case 3:
        return _buildTermsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProviderDetailsStep() {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your services and experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            
            // Bio
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Describe your experience and what you offer',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your bio';
                }
                if (value.trim().length < 20) {
                  return 'Bio must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Rate Type Selection
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

            // Rate Input based on selection
            if (_rateType == 'base')
              TextFormField(
                controller: _baseRateController,
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
              ),
            const SizedBox(height: 24),

            // Skills
            Text(
              'Skills',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      hintText: 'Add a skill',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSkill,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => _removeSkill(entry.key),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Service Categories
            Text(
              'Service Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = _selectedCategories.contains(category.id);
                  final displayName = _capitalizeWords(category.name);
                  return FilterChip(
                    label: Text(displayName),
                    selected: isSelected,
                    onSelected: (selected) {
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
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationStep() {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your identification documents for verification',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            _buildPhotoUploadCard(
              title: 'ID Document - Front',
              image: _idFrontImage,
              onTap: () => _pickImage('id_front', ImageSource.camera),
            ),
            const SizedBox(height: 16),

            _buildPhotoUploadCard(
              title: 'ID Document - Back',
              image: _idBackImage,
              onTap: () => _pickImage('id_back', ImageSource.camera),
            ),
            const SizedBox(height: 16),

            _buildPhotoUploadCard(
              title: 'Headshot Photo',
              image: _headshotImage,
              onTap: () => _pickImage('headshot', ImageSource.camera),
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to upload',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Center(
                      child: Image.file(
                        image,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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

  Widget _buildServicePhotosStep() {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Photos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload photos of your work for verification',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickServicePhotos,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Service Photos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_servicePhotos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _servicePhotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _servicePhotos[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeServicePhoto(index),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(4),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsStep() {
    return Form(
      key: _formKeys[3],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                context.push('/terms-and-conditions');
              },
              child: Row(
                children: [
                  Text(
                    'Terms & Conditions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please read and accept the terms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Terms of Service
            Card(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Service Provider Agreement\n\n'
                        'By registering as a service provider on HireMeBuddy, you agree to provide professional services to clients through our platform.\n\n'
                        '2. Professional Conduct\n\n'
                        'You agree to maintain professional standards and deliver quality services to all clients.\n\n'
                        '3. Verification\n\n'
                        'All identification documents and service photos will be verified by our team before your profile is activated.\n\n'
                        '4. Payment Terms\n\n'
                        'Platform fees apply to all transactions. Payments will be processed according to our payment schedule.\n\n'
                        '5. Account Termination\n\n'
                        'We reserve the right to suspend or terminate accounts that violate our terms of service.\n\n'
                        '6. Liability\n\n'
                        'Service providers are responsible for their own actions and services provided through the platform.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              title: GestureDetector(
                onTap: () {
                  context.push('/terms-and-conditions');
                },
                child: const Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Privacy Policy
            Card(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Data Collection\n\n'
                        'We collect personal information including your name, contact details, identification documents, and service photos for verification purposes.\n\n'
                        '2. Data Usage\n\n'
                        'Your information is used to verify your identity, display your profile to clients, and facilitate transactions on the platform.\n\n'
                        '3. Data Storage\n\n'
                        'All data is securely stored and encrypted. We comply with data protection regulations.\n\n'
                        '4. Data Sharing\n\n'
                        'We do not share your personal information with third parties except as required for platform operations or by law.\n\n'
                        '5. Your Rights\n\n'
                        'You have the right to access, modify, or delete your personal information at any time.\n\n'
                        '6. Cookies\n\n'
                        'We use cookies to improve your experience on the platform.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreedToPrivacy,
              onChanged: (value) {
                setState(() {
                  _agreedToPrivacy = value ?? false;
                });
              },
              title: GestureDetector(
                onTap: () {
                  context.push('/privacy-policy');
                },
                child: const Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    children: [
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }
}

class _GlassmorphismLoadingDialog extends StatefulWidget {
  const _GlassmorphismLoadingDialog();

  @override
  State<_GlassmorphismLoadingDialog> createState() => _GlassmorphismLoadingDialogState();
}

class _GlassmorphismLoadingDialogState extends State<_GlassmorphismLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.deepOrange.shade200.withOpacity(0.25),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.withOpacity(0.45),
                                blurRadius: 28,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Creating your provider account...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Please stay on this screen while we set up your services.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
