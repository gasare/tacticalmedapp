import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/patient_model.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _unitController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _historyController = TextEditingController();

  String _gender = 'Male';
  String _severity = 'Minor';

  String? _photoBase64;
  String? _woundPhotoBase64;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isWound) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          if (isWound) {
            _woundPhotoBase64 = base64Str;
          } else {
            _photoBase64 = base64Str;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newPatient = Patient(
          id: const Uuid().v4(),
          name: _nameController.text,
          age: int.tryParse(_ageController.text) ?? 0,
          gender: _gender,
          unit: _unitController.text,
          injuries: _injuriesController.text,
          medicalHistory: _historyController.text,
          registeredAt: DateTime.now(),
          severity: _severity,
          base64Photo: _photoBase64,
          base64WoundPhoto: _woundPhotoBase64,
        );

        final hiveService = ref.read(hiveServiceProvider);
        await hiveService.patientsBox.put(newPatient.id, newPatient);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Patient registered securely offline')),
          );
          context.go('/dashboard'); // Return distinctly to dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving patient: $e')),
          );
        }
      }
    }
  }

  Widget _buildImagePicker(String title, String? currentBase64, bool isWound) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(isWound),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2)),
            ),
            child: currentBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(currentBase64),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      Text('Tap to Capture',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12)),
                    ],
                  ),
          ),
        ),
        if (currentBase64 != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                if (isWound) {
                  _woundPhotoBase64 = null;
                } else {
                  _photoBase64 = null;
                }
              }),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Remove', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register Patient')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photos Section
              Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildImagePicker(
                            'Patient Photo', _photoBase64, false)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildImagePicker(
                            'Wound Photo', _woundPhotoBase64, true)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Basic Info Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Basic Information',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none)),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: 'Age',
                                    prefixIcon:
                                        const Icon(Icons.calendar_today),
                                    filled: true,
                                    fillColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none)),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: InputDecoration(
                                    labelText: 'Gender',
                                    filled: true,
                                    fillColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none)),
                                items: ['Male', 'Female']
                                    .map((g) => DropdownMenuItem(
                                        value: g, child: Text(g)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _gender = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _unitController,
                          decoration: InputDecoration(
                              labelText: 'Military Unit / Division',
                              prefixIcon: const Icon(Icons.shield),
                              filled: true,
                              fillColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none)),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Clinical Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clinical Details',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _severity,
                          decoration: InputDecoration(
                              labelText: 'Initial Severity',
                              prefixIcon: const Icon(Icons.warning),
                              filled: true,
                              fillColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none)),
                          items: ['Minor', 'Moderate', 'Critical']
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) => setState(() => _severity = val!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _injuriesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                              labelText: 'Injuries Description',
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none)),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _historyController,
                          maxLines: 2,
                          decoration: InputDecoration(
                              labelText: 'Medical History (Optional)',
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FilledButton.icon(
                  onPressed: _savePatient,
                  icon: const Icon(Icons.save),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Save',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
