import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/user_account.dart';

class AuthService {
  final HiveService _hiveService;
  final LocalAuthentication _localAuth;

  AuthService(this._hiveService, this._localAuth);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<bool> signUp(String username, String password, bool enableBiometrics, {String firstName = '', String lastName = '', String phoneNumber = ''}) async {
    final box = _hiveService.accountsBox;
    if (box.containsKey(username)) return false; // Username taken

    final account = UserAccount(
      username: username,
      hashedPassword: _hashPassword(password),
      biometricsEnabled: enableBiometrics,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
    await box.put(username, account);
    await _hiveService.authBox.put('last_logged_in_user', username);
    return true;
  }

  Future<bool> login(String username, String password) async {
    final box = _hiveService.accountsBox;
    final UserAccount? account = box.get(username);
    
    if (account == null) return false;

    if (account.hashedPassword == _hashPassword(password)) {
      await _hiveService.authBox.put('last_logged_in_user', username);
      return true;
    }
    return false;
  }
  
  UserAccount? getCurrentUser() {
    final username = _hiveService.authBox.get('last_logged_in_user');
    if (username == null) return null;
    return _hiveService.accountsBox.get(username);
  }
  
  Future<void> logout() async {
    await _hiveService.authBox.delete('last_logged_in_user');
  }

  Future<bool> canUseBiometrics() async {
    final user = getCurrentUser();
    if (user == null || !user.biometricsEnabled) return false;
    
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await canUseBiometrics()) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access TCOM patient records',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}

final localAuthProvider = Provider((ref) => LocalAuthentication());

final authServiceProvider = Provider<AuthService>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final localAuth = ref.watch(localAuthProvider);
  return AuthService(hiveService, localAuth);
});
