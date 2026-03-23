import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../domain/patient_model.dart';
import '../../cases/domain/case_model.dart';
import '../../../core/storage/hive_service.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  Patient? _patient;
  List<CaseRecord> _cases = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final hiveService = ref.read(hiveServiceProvider);
    setState(() {
      _patient = hiveService.patientsBox.get(widget.patientId) as Patient?;
      _cases = hiveService.casesBox.values
          .map((e) => e as CaseRecord)
          .where((c) => c.patientId == widget.patientId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  void _addCaseRecord() async {
    final noteController = TextEditingController();
    String noteType = 'Observation';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Case Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: noteType,
                items: ['Observation', 'Medication', 'Surgery', 'Discharge Note']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => noteType = val!,
                decoration: const InputDecoration(labelText: 'Record Type'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCase = CaseRecord(
                  id: const Uuid().v4(),
                  patientId: widget.patientId,
                  noteType: noteType,
                  description: noteController.text,
                  timestamp: DateTime.now(),
                  providerName: 'Current User',
                );

                final hiveService = ref.read(hiveServiceProvider);
                await hiveService.casesBox.put(newCase.id, newCase);
                if (context.mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_patient!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Severity: ${_patient!.severity}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _patient!.severity == 'Critical' ? Colors.red : (_patient!.severity == 'Moderate' ? Colors.orange : Colors.green),
                        )),
                        Text('Age: ${_patient!.age} | ${_patient!.gender}'),
                      ],
                    ),
                    const Divider(height: 32),
                    Text('Injuries', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_patient!.injuries),
                    const SizedBox(height: 16),
                    Text('Medical History', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_patient!.medicalHistory.isEmpty ? 'None provided' : _patient!.medicalHistory),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Timeline & Records', style: Theme.of(context).textTheme.headlineMedium),
                  TextButton.icon(
                    onPressed: _addCaseRecord,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Record'),
                  )
                ],
              ),
            ),
          ),
          _cases.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No case records yet.')),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = _cases[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            child: Icon(
                              c.noteType == 'Medication' ? Icons.medical_services :
                              c.noteType == 'Surgery' ? Icons.health_and_safety :
                              c.noteType == 'Discharge Note' ? Icons.exit_to_app : Icons.assignment,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(c.noteType),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(c.description),
                              const SizedBox(height: 8),
                              Text(DateFormat('MMM dd, yyyy - HH:mm').format(c.timestamp), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                    childCount: _cases.length,
                  ),
                )
        ],
      ),
    );
  }
}
