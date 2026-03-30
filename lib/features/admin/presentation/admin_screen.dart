import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/hive_service.dart';
import '../../auth/domain/user_account.dart';

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
      setState(() {});
    }
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
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
              subtitle: Text(account.isAdmin ? 'Superuser' : 'Standard Medic'),
              trailing: account.isAdmin 
                ? null 
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteUser(username),
                  ),
            ),
          );
        },
      ),
    );
  }
}
