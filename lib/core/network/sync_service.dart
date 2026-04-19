import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../features/patients/domain/patient_model.dart';
import '../../features/cases/domain/case_model.dart';
import '../../features/auth/domain/user_account.dart';
import 'dart:async';
import 'dart:developer' as developer;

class SyncService {
  final HiveService _hiveService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;
  StreamSubscription? _usersSubscription;

  SyncService(this._hiveService) {
    _initConnectivityListener();
    _initUsersListener();
  }

  void _initUsersListener() {
    _usersSubscription = _firestore.collection('users').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = doc.id;
        final localUser = _hiveService.accountsBox.get(username) as UserAccount?;
        
        if (localUser != null) {
          // Allow cloud to overwrite profile identity if modified by an Admin
          final updated = UserAccount(
             username: localUser.username,
             hashedPassword: localUser.hashedPassword,
             isAdmin: localUser.isAdmin,
             biometricsEnabled: localUser.biometricsEnabled,
             firstName: data['firstName'] ?? localUser.firstName,
             lastName: data['lastName'] ?? localUser.lastName,
             phoneNumber: data['phoneNumber'] ?? localUser.phoneNumber,
             isApproved: data['isApproved'] ?? localUser.isApproved,
             rank: data['rank'] ?? localUser.rank,
             unit: data['unit'] ?? localUser.unit,
             role: data['role'] ?? localUser.role,
             identificationType: data['identificationType'] ?? localUser.identificationType,
             profilePhotoBase64: data['profilePhotoBase64'] ?? localUser.profilePhotoBase64,
             isSynced: true,
          );
          // Only perform Hive write if data actually changed to avoid loop
          _hiveService.accountsBox.put(username, updated);
        }
      }
    });
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

      // 3. Sync User Accounts
      final accounts = _hiveService.accountsBox.values.cast<UserAccount>();
      for (final a in accounts) {
        if (!a.isSynced) {
          final docRef = _firestore.collection('users').doc(a.username);
          final payload = {
            'username': a.username,
            'firstName': a.firstName,
            'lastName': a.lastName,
            'phoneNumber': a.phoneNumber,
            'isAdmin': a.isAdmin,
            'isApproved': a.isApproved,
            'biometricsEnabled': a.biometricsEnabled,
            'rank': a.rank,
            'unit': a.unit,
            'role': a.role,
            'identificationType': a.identificationType,
            'profilePhotoBase64': a.profilePhotoBase64,
            'syncedAt': FieldValue.serverTimestamp(),
          };
          
          await docRef.set(payload, SetOptions(merge: true));
          
          final updatedAccount = UserAccount(
            username: a.username,
            hashedPassword: a.hashedPassword,
            isAdmin: a.isAdmin,
            biometricsEnabled: a.biometricsEnabled,
            firstName: a.firstName,
            lastName: a.lastName,
            phoneNumber: a.phoneNumber,
            isApproved: a.isApproved,
            rank: a.rank,
            unit: a.unit,
            role: a.role,
            identificationType: a.identificationType,
            profilePhotoBase64: a.profilePhotoBase64,
            isSynced: true,
          );
          await _hiveService.accountsBox.put(a.username, updatedAccount);
        }
      }

      developer.log('Sync Complete.', name: 'SyncService');
    } catch (e) {
      developer.log('Network error during sync: $e', name: 'SyncService');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _usersSubscription?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(hiveServiceProvider));
});
