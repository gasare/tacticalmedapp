import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
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
  final _injuriesController = TextEditingController();
  final _historyController = TextEditingController();
  
  String _gender = 'Male';
  String _severity = 'Stable';

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      final newPatient = Patient(
        id: const Uuid().v4(),
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _gender,
        injuries: _injuriesController.text,
        medicalHistory: _historyController.text,
        registeredAt: DateTime.now(),
        severity: _severity,
      );
      
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.patientsBox.put(newPatient.id, newPatient);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient registered securely offline')),
        );
        context.pop(); // Return to dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.calendar_today)),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _severity,
                decoration: const InputDecoration(labelText: 'Initial Severity', prefixIcon: Icon(Icons.warning)),
                items: ['Stable', 'Moderate', 'Critical'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _severity = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _injuriesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Injuries Description', alignLabelWithHint: true),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _historyController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Medical History (Optional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savePatient,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Record Offline'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
