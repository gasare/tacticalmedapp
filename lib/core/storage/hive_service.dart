import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HiveService {
  static const String _secureKey = 'encryption_key';
  static const String patientsBoxName = 'patients_box';
  static const String casesBoxName = 'cases_box';
  static const String authBoxName = 'auth_box'; // For PINs/Hashes

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    // Check if we have an encryption key stored securely
    String? storedKey = await _secureStorage.read(key: _secureKey);
    List<int> encryptionKey;

    if (storedKey == null) {
      // First run: generate a new 256-bit encryption key securely
      final secureKey = Hive.generateSecureKey();
      await _secureStorage.write(key: _secureKey, value: base64UrlEncode(secureKey));
      encryptionKey = secureKey;
    } else {
      // Decode the stored key
      encryptionKey = base64Url.decode(storedKey);
    }

    // Open encrypted boxes with AES-256
    await Hive.openBox(patientsBoxName, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(casesBoxName, encryptionCipher: HiveAesCipher(encryptionKey));
    
    // Auth box without heavy encryption for initial fast PIN verification
    await Hive.openBox(authBoxName);
  }

  Box get patientsBox => Hive.box(patientsBoxName);
  Box get casesBox => Hive.box(casesBoxName);
  Box get authBox => Hive.box(authBoxName);
}

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('hiveService not initialized');
});
