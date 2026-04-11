import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../domain/patient_model.dart';
import '../../cases/domain/case_model.dart';
import '../../../core/storage/hive_service.dart';
import '../data/pdf_service.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  Patient? _patient;
  List<CaseRecord> _cases = [];
  late stt.SpeechToText _speechToText;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
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
                initialValue: noteType,
                items: [
                  'Observation',
                  'Medication',
                  'Surgery',
                  'Discharge Note'
                ]
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

  void _addRapidRecord(String type, String desc) async {
    final newCase = CaseRecord(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      noteType: type,
      description: desc,
      timestamp: DateTime.now(),
      providerName: 'Tactical Medic',
    );
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.casesBox.put(newCase.id, newCase);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$desc logged to timeline')));
    }
    _loadData();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
         return;
      }

      bool available = await _speechToText.initialize(
        onStatus: (val) {
           if (val == 'done' || val == 'notListening') {
             if (_isListening) {
               setState(() => _isListening = false);
               if (_speechToText.lastRecognizedWords.isNotEmpty) {
                 _addRapidRecord('Audio Dictation', _speechToText.lastRecognizedWords);
               }
             }
           }
        },
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) {
            // we handle the final dispatch in the onStatus='done' block above!
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _showQrCodeDialog() {
    if (_patient == null) return;
    
    final payload = {
      'id': _patient!.id,
      'name': _patient!.name,
      'age': _patient!.age,
      'gender': _patient!.gender,
      'severity': _patient!.severity,
      'injuries': _patient!.injuries,
      'medicalHistory': _patient!.medicalHistory,
      'unit': _patient!.unit,
      'gpsLocation': _patient!.gpsLocation,
      'registeredAt': _patient!.registeredAt.toIso8601String(),
    };
    final jsonStr = jsonEncode(payload);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Patient Handoff QR'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: jsonStr,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
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
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Handoff via QR',
            onPressed: _showQrCodeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Share PDF Report',
            onPressed: () async {
              if (_patient != null) {
                await PdfService.generateAndSharePatientReport(_patient!);
              }
            },
          ),
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
                        Text('Severity: ${_patient!.severity}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: _patient!.severity == 'Critical'
                                      ? Colors.red
                                      : (_patient!.severity == 'Moderate'
                                          ? Colors.orange
                                          : Colors.green),
                                )),
                        Text(
                            'Age: ${_patient!.age} | ${_patient!.gender}${_patient!.unit != null && _patient!.unit!.isNotEmpty ? ' | Unit: ${_patient!.unit}' : ''}'),
                      ],
                    ),
                    const Divider(height: 32),
                    Text('Injuries',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_patient!.injuries),
                    const SizedBox(height: 16),
                    Text('Medical History',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_patient!.medicalHistory.isEmpty
                        ? 'None provided'
                        : _patient!.medicalHistory),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Timeline & Records',
                      style: Theme.of(context).textTheme.headlineMedium),
                  TextButton.icon(
                    onPressed: _addCaseRecord,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Record'),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ActionChip(
                    avatar: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 16, color: _isListening ? Colors.redAccent : null),
                    label: Text(_isListening ? 'Listening...' : 'Dictate'),
                    backgroundColor: _isListening ? Colors.redAccent.withValues(alpha: 0.1) : null,
                    onPressed: _toggleListening,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.vaccines, size: 16),
                    label: const Text('Morphine'),
                    onPressed: () => _addRapidRecord('Medication', 'Administered Morphine (10mg IV)'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.healing, size: 16),
                    label: const Text('Tourniquet'),
                    onPressed: () => _addRapidRecord('Surgery', 'Applied Tourniquet to control hemorrhage'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.water_drop, size: 16),
                    label: const Text('Whole Blood'),
                    onPressed: () => _addRapidRecord('Observation', 'Initiated Whole Blood Transfusion'),
                  ),
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.2),
                            child: Icon(
                              c.noteType == 'Medication'
                                  ? Icons.medical_services
                                  : c.noteType == 'Surgery'
                                      ? Icons.health_and_safety
                                      : c.noteType == 'Discharge Note'
                                          ? Icons.exit_to_app
                                          : Icons.assignment,
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
                              Text(
                                  DateFormat('MMM dd, yyyy - HH:mm')
                                      .format(c.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall),
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
