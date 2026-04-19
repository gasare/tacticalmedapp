import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/patients/domain/patient_model.dart';
import '../../features/cases/domain/case_model.dart';
import '../../features/auth/domain/user_account.dart';

class HiveService {
  static const String _secureKey = 'encryption_key';
  static const String patientsBoxName = 'patients_box';
  static const String casesBoxName = 'cases_box';
  static const String authBoxName = 'auth_box'; // For PINs/Hashes/Legacy
  static const String settingsBoxName = 'settings_box';
  static const String accountsBoxName = 'accounts_box';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PatientAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CaseRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserAccountAdapter());
    }

    // Check if we have an encryption key stored securely
    String? storedKey;
    try {
      storedKey = await _secureStorage.read(key: _secureKey);
    } catch (e) {
      await _secureStorage.deleteAll();
      storedKey = null;
    }

    List<int> encryptionKey;

    if (storedKey == null) {
      final secureKey = Hive.generateSecureKey();
      try {
        await _secureStorage.write(key: _secureKey, value: base64UrlEncode(secureKey));
      } catch (_) {}
      encryptionKey = secureKey;
    } else {
      try {
        encryptionKey = base64Url.decode(storedKey);
      } catch (e) {
        await _secureStorage.deleteAll();
        final secureKey = Hive.generateSecureKey();
        try {
          await _secureStorage.write(key: _secureKey, value: base64UrlEncode(secureKey));
        } catch (_) {}
        encryptionKey = secureKey;
      }
    }

    // Open encrypted boxes with AES-256
    await Hive.openBox(patientsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(casesBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey));

    // Auth box without heavy encryption for initial fast PIN verification
    await Hive.openBox(authBoxName);

    // Accounts box for multi-user authentication
    await Hive.openBox(accountsBoxName);

    // Settings box for medic profile
    await Hive.openBox(settingsBoxName);
  }

  Box get patientsBox => Hive.box(patientsBoxName);
  Box get casesBox => Hive.box(casesBoxName);
  Box get authBox => Hive.box(authBoxName);
  Box get accountsBox => Hive.box(accountsBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);
}

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('hiveService not initialized');
});
