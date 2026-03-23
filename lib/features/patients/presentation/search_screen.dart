import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/patient_model.dart';
import 'package:intl/intl.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  String _severityFilter = 'All';

  @override
  void initState() {
    super.initState();
    final hiveService = ref.read(hiveServiceProvider);
    _allPatients = hiveService.patientsBox.values.map((e) => e as Patient).toList();
    _filteredPatients = List.from(_allPatients);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        final matchesQuery = p.name.toLowerCase().contains(query) || p.id.toLowerCase().contains(query);
        final matchesSeverity = _severityFilter == 'All' || p.severity == _severityFilter;
        return matchesQuery && matchesSeverity;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by Name or ID...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (_) => _filter(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              _severityFilter = val;
              _filter();
            },
            itemBuilder: (context) => ['All', 'Stable', 'Moderate', 'Critical']
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
          )
        ],
      ),
      body: _filteredPatients.isEmpty
          ? const Center(child: Text('No matching patients found.'))
          : ListView.builder(
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final p = _filteredPatients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('ID: ${p.id.substring(0, 8)}...\nAdded ${DateFormat('MMMd yyyy').format(p.registeredAt)}'),
                    isThreeLine: true,
                    trailing: Text(p.severity, style: TextStyle(
                      color: p.severity == 'Critical' ? Colors.red : (p.severity == 'Moderate' ? Colors.orange : Colors.green),
                      fontWeight: FontWeight.bold
                    )),
                    onTap: () {
                      context.push('/patient/${p.id}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
