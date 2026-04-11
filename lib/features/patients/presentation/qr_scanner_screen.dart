import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/storage/hive_service.dart';
import '../domain/patient_model.dart';
import 'package:uuid/uuid.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      try {
        final data = jsonDecode(code);
        
        // Make sure it looks like a patient model
        if (data is Map<String, dynamic> && data.containsKey('name')) {
          final hiveService = ref.read(hiveServiceProvider);
          
          final patient = Patient(
            id: data['id'] ?? const Uuid().v4(),
            name: data['name'] ?? 'Unknown',
            age: data['age'] ?? 0,
            gender: data['gender'] ?? 'Unknown',
            severity: data['severity'] ?? 'Moderate',
            injuries: data['injuries'] ?? 'No data',
            medicalHistory: data['medicalHistory'] ?? '',
            unit: data['unit'],
            gpsLocation: data['gpsLocation'],
            registeredAt: data['registeredAt'] != null ? DateTime.parse(data['registeredAt']) : DateTime.now(),
          );

          await hiveService.patientsBox.put(patient.id, patient);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received patient: ${patient.name}')),
            );
            context.go('/');
          }
        } else {
          throw const FormatException('Invalid Patient QR Data');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read QR Code')),
          );
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Patient Handoff')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Align QR code within frame',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
