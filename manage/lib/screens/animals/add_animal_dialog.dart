import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/camera_service.dart';

/// Check if running on mobile platform
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

class AddAnimalDialog extends ConsumerStatefulWidget {
  final Animal? animal; // For editing

  const AddAnimalDialog({super.key, this.animal});

  @override
  ConsumerState<AddAnimalDialog> createState() => _AddAnimalDialogState();
}

class _AddAnimalDialogState extends ConsumerState<AddAnimalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tagIdController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  late AnimalType _selectedSpecies;
  late Gender _selectedGender;
  late DateTime? _birthDate;
  late AnimalStatus _selectedStatus;
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    final animal = widget.animal;
    _tagIdController = TextEditingController(text: animal?.tagId ?? '');
    _nameController = TextEditingController(text: animal?.name ?? '');
    _breedController = TextEditingController(text: animal?.breed ?? '');
    _weightController = TextEditingController(
      text: animal?.currentWeight?.toString() ?? '',
    );
    _notesController = TextEditingController(text: animal?.notes ?? '');
    _selectedSpecies = animal?.species ?? AnimalType.cattle;
    _selectedGender = animal?.gender ?? Gender.female;
    _birthDate = animal?.birthDate;
    _selectedStatus = animal?.status ?? AnimalStatus.healthy;
    _existingPhotoUrl = animal?.photoUrl;
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.animal != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Modern Header with Gradient
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit : Icons.pets,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Animal' : 'Add New Animal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? 'Update animal information'
                            : 'Register a new animal to your farm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Section
                    _buildPhotoSection(context),
                    const SizedBox(height: 20),

                    // Basic Info Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.info_outline,
                      title: 'Basic Information',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),

                    // Tag ID
                    _buildModernTextField(
                      controller: _tagIdController,
                      label: 'Tag ID',
                      icon: Icons.tag,
                      iconColor: Colors.blue,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Name (optional)
                    _buildModernTextField(
                      controller: _nameController,
                      label: 'Name (optional)',
                      icon: Icons.badge,
                      iconColor: Colors.purple,
                      helperText: 'Give your animal a name',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // Species & Breed Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.category,
                      title: 'Species & Breed',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    // Species Selection Chips
                    _buildSpeciesSelector(context),
                    const SizedBox(height: 12),

                    // Breed
                    _buildModernTextField(
                      controller: _breedController,
                      label: 'Breed (optional)',
                      icon: Icons.pets,
                      iconColor: Colors.teal,
                    ),
                    const SizedBox(height: 20),

                    // Details Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.details,
                      title: 'Details',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),

                    // Gender Selection
                    _buildGenderSelector(context),
                    const SizedBox(height: 12),

                    // Birth Date Card
                    _buildDateCard(context),
                    const SizedBox(height: 12),

                    // Weight
                    _buildModernTextField(
                      controller: _weightController,
                      label: 'Current Weight (kg)',
                      icon: Icons.monitor_weight,
                      iconColor: Colors.indigo,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Status Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.health_and_safety,
                      title: 'Status',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusSelector(context),
                    const SizedBox(height: 20),

                    // Notes Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.notes,
                      title: 'Additional Notes',
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _notesController,
                      label: 'Notes (optional)',
                      icon: Icons.notes,
                      iconColor: Colors.grey,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton(
                      onPressed: _isLoading ? null : _saveAnimal,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isEditing ? Icons.save : Icons.add),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing ? 'Update Animal' : 'Add Animal',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? helperText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildSpeciesSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnimalType.values.map((species) {
        final isSelected = _selectedSpecies == species;
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(species.icon),
              const SizedBox(width: 6),
              Text(species.displayName),
            ],
          ),
          onSelected: (_) => setState(() => _selectedSpecies = species),
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: Gender.values.map((gender) {
        final isSelected = _selectedGender == gender;
        final color = gender == Gender.male ? Colors.blue : Colors.pink;
        final icon = gender == Gender.male ? Icons.male : Icons.female;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: gender == Gender.male ? 8 : 0,
              left: gender == Gender.female ? 8 : 0,
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedGender = gender),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      gender.name.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected ? color : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _birthDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _birthDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cake, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birth Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _birthDate != null
                        ? DateFormat.yMMMd().format(_birthDate!)
                        : 'Tap to select date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_birthDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _birthDate = null),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.error,
                ),
              )
            else
              Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnimalStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        final color = _getStatusColor(status);

        return FilterChip(
          selected: isSelected,
          label: Text(status.name.toUpperCase()),
          onSelected: (_) => setState(() => _selectedStatus = status),
          selectedColor: color.withValues(alpha: 0.2),
          checkmarkColor: color,
          backgroundColor: colorScheme.surfaceContainerHighest,
          labelStyle: TextStyle(
            color: isSelected ? color : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(AnimalStatus status) {
    switch (status) {
      case AnimalStatus.healthy:
        return Colors.green;
      case AnimalStatus.sick:
        return Colors.red;
      case AnimalStatus.pregnant:
        return Colors.purple;
      case AnimalStatus.nursing:
        return Colors.blue;
      case AnimalStatus.sold:
        return Colors.orange;
      case AnimalStatus.deceased:
        return Colors.grey;
    }
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    final farmId = ref.read(activeFarmIdProvider);
    if (farmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a farm first'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(animalRepositoryProvider);
      final now = DateTime.now();

      final animal = Animal(
        id: widget.animal?.id ?? '',
        farmId: widget.animal?.farmId ?? farmId,
        tagId: _tagIdController.text.trim(),
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        gender: _selectedGender,
        birthDate: _birthDate,
        currentWeight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.animal?.createdAt ?? now,
        updatedAt: now,
        photoUrl: _existingPhotoUrl,
        photoGallery: widget.animal?.photoGallery ?? [],
        motherId: widget.animal?.motherId,
        fatherId: widget.animal?.fatherId,
        purchasePrice: widget.animal?.purchasePrice,
        purchaseDate: widget.animal?.purchaseDate,
      );

      if (widget.animal != null) {
        // Pass the previous animal to track changes for weight/status
        await repository.updateAnimal(animal, previousAnimal: widget.animal);
      } else {
        await repository.addAnimal(animal);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.animal != null
                      ? 'Animal updated successfully'
                      : 'Animal added successfully',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Photo preview
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _selectedImage != null
                  ? FutureBuilder<dynamic>(
                      future: _selectedImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(snapshot.data, fit: BoxFit.cover);
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : _existingPhotoUrl != null
                  ? Image.network(
                      _existingPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.pets,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(Icons.pets, size: 36, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          // Photo actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal Photo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a photo to identify your animal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Only show camera button on mobile
                    if (_isMobilePlatform)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _takePhoto,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 18),
                              SizedBox(width: 6),
                              Text('Camera'),
                            ],
                          ),
                        ),
                      ),
                    if (_isMobilePlatform) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickPhoto,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 18),
                            SizedBox(width: 6),
                            Text('Gallery'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final cameraService = CameraService();
    if (!cameraService.isCameraAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera is not available on this platform. Please use Gallery instead.',
            ),
          ),
        );
      }
      return;
    }

    final image = await cameraService.capturePhoto();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final cameraService = CameraService();
    if (!cameraService.isGalleryAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery is not available on this platform'),
          ),
        );
      }
      return;
    }

    final image = await cameraService.pickFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }
}
