import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../features/patients/domain/patient_model.dart';
import 'dart:developer' as developer;

class SyncService {
  final HiveService _hiveService;
  final FirebaseFirestore _firestore;

  SyncService(this._hiveService) : _firestore = FirebaseFirestore.instance;

  Future<void> syncOfflinePatients() async {
    final box = _hiveService.patientsBox;
    List<dynamic> keysToUpdate = [];

    developer.log('Starting Cloud Sync...', name: 'SyncService');

    try {
      for (var key in box.keys) {
        final Patient patient = box.get(key);
        
        if (!patient.isSynced) {
          // Upload to Firestore
          await _firestore.collection('patients').doc(patient.id).set({
            'id': patient.id,
            'name': patient.name,
            'age': patient.age,
            'gender': patient.gender,
            'gpsLocation': patient.gpsLocation,
            'injuries': patient.injuries,
            'medicalHistory': patient.medicalHistory,
            'registeredAt': patient.registeredAt.toIso8601String(),
            'severity': patient.severity,
            'unit': patient.unit,
            // Only sync lightweight data, dropping massive base64 images to save bandwidth in the field
            'hasPhoto': patient.base64Photo != null,
            'hasWoundPhoto': patient.base64WoundPhoto != null,
            'syncedAt': FieldValue.serverTimestamp(),
          });

          keysToUpdate.add(key);
        }
      }

      // Update the local Hive objects to marked as synced
      for (var key in keysToUpdate) {
        final Patient patient = box.get(key);
        final updatedPatient = Patient(
          id: patient.id,
          name: patient.name,
          age: patient.age,
          gender: patient.gender,
          gpsLocation: patient.gpsLocation,
          base64Photo: patient.base64Photo,
          injuries: patient.injuries,
          medicalHistory: patient.medicalHistory,
          registeredAt: patient.registeredAt,
          severity: patient.severity,
          unit: patient.unit,
          base64WoundPhoto: patient.base64WoundPhoto,
          isSynced: true, // Marked True!
        );
        await box.put(key, updatedPatient);
      }
      
      developer.log('Successfully synced ${keysToUpdate.length} patients to the Cloud.', name: 'SyncService');
    } catch (e) {
      developer.log('Network error during sync: $e', name: 'SyncService');
      // Quietly fail for offline mode
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(hiveServiceProvider));
});
