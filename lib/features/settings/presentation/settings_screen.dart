import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/hive_service.dart';
import '../../../app.dart';
import '../../auth/data/auth_service.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../auth/domain/user_account.dart';

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

  String? _profilePhotoBase64;
  String _identificationType = 'Soldier';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final currentUser = ref.read(authServiceProvider).getCurrentUser();

    if (currentUser != null) {
      _nameController.text = "${currentUser.firstName} ${currentUser.lastName}".trim();
      if (_nameController.text.isEmpty) _nameController.text = currentUser.username;
      
      _rankController.text = currentUser.rank;
      _unitController.text = currentUser.unit;
      _roleController.text = currentUser.role;
      _identificationType = currentUser.identificationType.isEmpty ? 'Soldier' : currentUser.identificationType;
      _profilePhotoBase64 = currentUser.profilePhotoBase64;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profilePhotoBase64 = base64Encode(bytes);
      });
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final hiveService = ref.read(hiveServiceProvider);
      final currentUser = ref.read(authServiceProvider).getCurrentUser();
      if (currentUser == null) return;
      
      final parts = _nameController.text.trim().split(' ');
      final first = parts.isNotEmpty ? parts.first : '';
      final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      
      final updatedUser = UserAccount(
        username: currentUser.username,
        hashedPassword: currentUser.hashedPassword,
        isAdmin: currentUser.isAdmin,
        biometricsEnabled: currentUser.biometricsEnabled,
        isApproved: currentUser.isApproved,
        firstName: first,
        lastName: last,
        phoneNumber: currentUser.phoneNumber,
        rank: _rankController.text.trim(),
        unit: _unitController.text.trim(),
        role: _roleController.text.trim(),
        identificationType: _identificationType,
        profilePhotoBase64: _profilePhotoBase64 ?? '',
        isSynced: false,
      );

      hiveService.accountsBox.put(currentUser.username, updatedUser);

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
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: _profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty
                    ? MemoryImage(base64Decode(_profilePhotoBase64!))
                    : null,
                child: _profilePhotoBase64 == null || _profilePhotoBase64!.isEmpty
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _identificationType,
              decoration: const InputDecoration(
                labelText: 'Identification Type',
                prefixIcon: Icon(Icons.badge),
              ),
              items: ['Soldier', 'Civilian']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() { _identificationType = v; });
              },
            ),
            const SizedBox(height: 16),
            
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
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Tactical Night Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Preserve night vision with deep red filtering'),
              secondary: const Icon(Icons.nightlight_round),
              value: ref.watch(themeProvider) == ThemeMode.dark,
              onChanged: (val) {
                ref.read(themeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
              },
              activeTrackColor: Colors.red.withValues(alpha: 0.5),
              activeThumbColor: Colors.red,
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('SECURE LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
