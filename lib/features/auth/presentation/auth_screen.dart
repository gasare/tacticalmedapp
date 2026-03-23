import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final authService = ref.read(authServiceProvider);
    final isRegistered = await authService.hasRegisteredPin();
    
    // Attempt biometric right away if registered
    if (isRegistered) {
      final success = await authService.authenticateWithBiometrics();
      if (success && mounted) {
        context.go('/');
        return;
      }
    }
    
    setState(() {
      _isRegistering = !isRegistered;
      _isLoading = false;
    });
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = ref.read(authServiceProvider);
    
    if (_isRegistering) {
      await authService.registerPin(pin);
      if (mounted) context.go('/');
    } else {
      final isValid = await authService.verifyPin(pin);
      if (isValid) {
        if (mounted) context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN';
          _isLoading = false;
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  _isRegistering ? 'Create Security PIN' : 'Enter PIN',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegistering 
                      ? 'This PIN will be used to encrypt your offline data.'
                      : 'Please authenticate to access records.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 8, fontSize: 24),
                  decoration: InputDecoration(
                    hintText: '****',
                    errorText: _errorMessage.isEmpty ? null : _errorMessage,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submitPin(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitPin,
                    child: Text(_isRegistering ? 'Set PIN' : 'Unlock'),
                  ),
                ),
                if (!_isRegistering) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      final success = await ref.read(authServiceProvider).authenticateWithBiometrics();
                      if (success && context.mounted) {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometrics'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
