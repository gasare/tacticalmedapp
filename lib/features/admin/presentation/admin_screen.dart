import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/storage/hive_service.dart';
import '../../auth/domain/user_account.dart';
import '../../patients/domain/patient_model.dart';
import '../data/mascal_export_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  
  void _deleteUser(String username) async {
    if (username == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete root admin account!')),
      );
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to permanently delete user "$username"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
    
    if (confirm == true) {
      final hive = ref.read(hiveServiceProvider);
      await hive.accountsBox.delete(username);
      try {
        await FirebaseFirestore.instance.collection('users').doc(username).delete();
      } catch (e) {
         // handle offline deletion gracefully
      }
      setState(() {});
    }
  }

  void _editUser(UserAccount account) {
    final nameCtrl = TextEditingController(text: '${account.firstName} ${account.lastName}'.trim());
    final rankCtrl = TextEditingController(text: account.rank);
    final unitCtrl = TextEditingController(text: account.unit);
    final roleCtrl = TextEditingController(text: account.role);
    String identType = account.identificationType.isEmpty ? 'Soldier' : account.identificationType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Profile: ${account.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: identType,
                decoration: const InputDecoration(labelText: 'Identification Type'),
                items: ['Soldier', 'Civilian'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => identType = v ?? 'Soldier',
              ),
              const SizedBox(height: 8),
              TextField(controller: rankCtrl, decoration: const InputDecoration(labelText: 'Rank(e.g., PVT)')),
              const SizedBox(height: 8),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
              const SizedBox(height: 8),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (e.g., 68W)')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final parts = nameCtrl.text.trim().split(' ');
                    final first = parts.isNotEmpty ? parts.first : '';
                    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                    
                    final updated = UserAccount(
                      username: account.username,
                      hashedPassword: account.hashedPassword,
                      isAdmin: account.isAdmin,
                      biometricsEnabled: account.biometricsEnabled,
                      isApproved: account.isApproved,
                      firstName: first,
                      lastName: last,
                      phoneNumber: account.phoneNumber,
                      rank: rankCtrl.text.trim(),
                      unit: unitCtrl.text.trim(),
                      role: roleCtrl.text.trim(),
                      identificationType: identType,
                      profilePhotoBase64: account.profilePhotoBase64,
                      isSynced: false,
                    );
                    
                    final hive = ref.read(hiveServiceProvider);
                    hive.accountsBox.put(account.username, updated);
                    
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(account.username).update({
                        'firstName': first,
                        'lastName': last,
                        'rank': rankCtrl.text.trim(),
                        'unit': unitCtrl.text.trim(),
                        'role': roleCtrl.text.trim(),
                        'identificationType': identType,
                      });
                      
                      final synced = UserAccount(
                        username: account.username,
                        hashedPassword: account.hashedPassword,
                        isAdmin: account.isAdmin,
                        biometricsEnabled: account.biometricsEnabled,
                        isApproved: account.isApproved,
                        firstName: first,
                        lastName: last,
                        phoneNumber: account.phoneNumber,
                        rank: rankCtrl.text.trim(),
                        unit: unitCtrl.text.trim(),
                        role: roleCtrl.text.trim(),
                        identificationType: identType,
                        profilePhotoBase64: account.profilePhotoBase64,
                        isSynced: true,
                      );
                      hive.accountsBox.put(account.username, synced);
                    } catch (e) {
                       if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase UI Update Delayed: $e')));
                       }
                    }
                    
                    if (context.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('SAVE IDENTITY'),
                ),
              ),
              const SizedBox(height: 16),
            ]
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final hive = ref.watch(hiveServiceProvider);
    final accounts = hive.accountsBox.keys.map((k) => k as String).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM ADMIN'),
        backgroundColor: Theme.of(context).colorScheme.error,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => context.go('/'),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('GENERATE MASCAL REPORT (CSV)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: () {
                  final patients = hive.patientsBox.values.map((e) => e as Patient).toList();
                  MascalExportService.generateAndShareCSV(patients);
                },
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final username = accounts[index];
          final UserAccount? account = hive.accountsBox.get(username);
          
          if (account == null) return const SizedBox.shrink();
          
          return Card(
            child: ListTile(
              leading: Icon(
                account.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: account.isAdmin ? Colors.red : Theme.of(context).colorScheme.primary,
              ),
              title: Text(account.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(account.isAdmin ? 'Superuser' : (account.isApproved ? 'Approved Medic' : 'Pending Approval')),
              trailing: account.isAdmin 
                ? null 
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: account.isApproved,
                        activeColor: Colors.green,
                        onChanged: (val) async {
                          final updated = UserAccount(
                             username: account.username,
                             hashedPassword: account.hashedPassword,
                             isAdmin: account.isAdmin,
                             biometricsEnabled: account.biometricsEnabled,
                             firstName: account.firstName,
                             lastName: account.lastName,
                             phoneNumber: account.phoneNumber,
                             isApproved: val,
                             isSynced: false,
                          );
                          hive.accountsBox.put(username, updated);
                          
                          try {
                             await FirebaseFirestore.instance.collection('users').doc(username).update({'isApproved': val});
                             final synced = UserAccount(
                                username: account.username,
                                hashedPassword: account.hashedPassword,
                                isAdmin: account.isAdmin,
                                biometricsEnabled: account.biometricsEnabled,
                                firstName: account.firstName,
                                lastName: account.lastName,
                                phoneNumber: account.phoneNumber,
                                isApproved: val,
                                isSynced: true,
                             );
                             hive.accountsBox.put(username, synced);
                          } catch (e) {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase UI Update Delayed: $e')));
                             }
                          }
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(account),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteUser(username),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
     ),
    ]
    ),
    );
  }
}

