import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/user_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rankController = TextEditingController();
  final _unitController = TextEditingController();
  final _roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final hiveService = ref.read(hiveServiceProvider);
    final box = hiveService.settingsBox;
    if (box.isNotEmpty) {
      final UserSettings? settings = box.get('medic_profile');
      if (settings != null) {
        _nameController.text = settings.providerName;
        _rankController.text = settings.rank;
        _unitController.text = settings.unit;
        _roleController.text = settings.role;
      }
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final hiveService = ref.read(hiveServiceProvider);
      
      final settings = UserSettings(
        providerName: _nameController.text.trim(),
        rank: _rankController.text.trim(),
        unit: _unitController.text.trim(),
        role: _roleController.text.trim(),
      );

      hiveService.settingsBox.put('medic_profile', settings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medic Profile Saved Successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rankController.dispose();
    _unitController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medic Profile Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.shield_outlined, size: 80, color: Color(0xFF0F172A)),
            const SizedBox(height: 16),
            const Text(
              'Identity Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This information will automatically be attached to all patient PDFs you generate.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _rankController.text.isEmpty ? null : _rankController.text,
              decoration: const InputDecoration(
                labelText: 'Rank',
                prefixIcon: Icon(Icons.military_tech_outlined),
              ),
              items: ['CIV', 'PVT', 'PFC', 'CPL', 'SGT', 'SSG', 'SFC', 'MSG', '1SG', 'SGM', 'CSM', '2LT', '1LT', 'CPT', 'MAJ', 'LTC', 'COL']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _rankController.text = v;
              },
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit / Batch',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _roleController.text.isEmpty ? null : _roleController.text,
              decoration: const InputDecoration(
                labelText: 'Role / Specialty',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: ['Combat Medic (68W)', 'Nurse', 'Physician', 'Surgeon', 'First Responder']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _roleController.text = v;
              },
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('SAVE IDENTITY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
