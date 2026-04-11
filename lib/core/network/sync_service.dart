import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../features/patients/domain/patient_model.dart';
import '../../features/cases/domain/case_model.dart';
import 'dart:async';
import 'dart:developer' as developer;

class SyncService {
  final HiveService _hiveService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  SyncService(this._hiveService) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile)) {
        syncAllData();
      }
    });
  }

  Future<void> syncAllData() async {
    developer.log('Starting Cloud Sync...', name: 'SyncService');
    try {
      // 1. Sync Patients
      final patients = _hiveService.patientsBox.values.cast<Patient>();
      for (final p in patients) {
        if (!p.isSynced) {
          final docRef = _firestore.collection('patients').doc(p.id);
          final payload = {
            'id': p.id,
            'name': p.name,
            'age': p.age,
            'gender': p.gender,
            'severity': p.severity,
            'injuries': p.injuries,
            'medicalHistory': p.medicalHistory,
            'unit': p.unit,
            'gpsLocation': p.gpsLocation,
            'registeredAt': p.registeredAt.toIso8601String(),
            'hasWoundPhoto': p.base64WoundPhoto != null,
            'syncedAt': FieldValue.serverTimestamp(),
          };
          
          await docRef.set(payload, SetOptions(merge: true));
          
          final updatedPat = Patient(
            id: p.id,
            name: p.name,
            age: p.age,
            gender: p.gender,
            severity: p.severity,
            injuries: p.injuries,
            medicalHistory: p.medicalHistory,
            registeredAt: p.registeredAt,
            gpsLocation: p.gpsLocation,
            unit: p.unit,
            base64WoundPhoto: p.base64WoundPhoto,
            isSynced: true,
          );
          await _hiveService.patientsBox.put(p.id, updatedPat);
        }
      }

      // 2. Sync Cases
      final cases = _hiveService.casesBox.values.cast<CaseRecord>();
      for (final c in cases) {
        if (!c.isSynced) {
          final docRef = _firestore.collection('case_records').doc(c.id);
          final payload = {
            'id': c.id,
            'patientId': c.patientId,
            'noteType': c.noteType,
            'description': c.description,
            'providerName': c.providerName,
            'timestamp': c.timestamp.toIso8601String(),
            'syncedAt': FieldValue.serverTimestamp(),
          };
          
          await docRef.set(payload, SetOptions(merge: true));
          
          final updatedCase = CaseRecord(
            id: c.id,
            patientId: c.patientId,
            noteType: c.noteType,
            description: c.description,
            timestamp: c.timestamp,
            providerName: c.providerName,
            isSynced: true,
          );
          await _hiveService.casesBox.put(c.id, updatedCase);
        }
      }
      developer.log('Sync Complete.', name: 'SyncService');
    } catch (e) {
      developer.log('Network error during sync: $e', name: 'SyncService');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(hiveServiceProvider));
});
