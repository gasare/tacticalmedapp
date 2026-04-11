import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/patient_model.dart';
import 'package:intl/intl.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialFilter;
  const SearchScreen({super.key, this.initialFilter = 'All'});

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
    _severityFilter = widget.initialFilter;
    _filter();
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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _filteredPatients.isEmpty
              ? const Center(child: Text('No matching patients found.'))
          : ListView.builder(
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final p = _filteredPatients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('ID: ${p.id.substring(0, 8)}...\nAdded ${DateFormat('MMMd yyyy').format(p.registeredAt)}'),
                    isThreeLine: true,
                    trailing: Text(p.severity, style: TextStyle(
                      color: p.severity == 'Critical' ? Colors.red : (p.severity == 'Moderate' ? Colors.orange : (p.severity == 'Minor' ? Colors.green : Colors.black87)),
                      fontWeight: FontWeight.bold
                    )),
                    onTap: () {
                      context.push('/patient/${p.id}');
                    },
                  ),
                ).animate().fade(duration: 250.ms, delay: (50 * index).ms).slideX(begin: 0.1);
              },
            ),
        ),
      ),
    );
  }
}
