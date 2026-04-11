import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // New Fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _enableBiometrics = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final authService = ref.read(authServiceProvider);
    if (await authService.canUseBiometrics()) {
      final success = await authService.authenticateWithBiometrics();
      if (success && mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = ref.read(authServiceProvider);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      final success = await authService.login(username, password);
      if (success && mounted) {
        context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password.';
          _isLoading = false;
        });
      }
    } else {
      // Registration: Trigger Firebase SMS flow
      await _verifyPhoneNumber();
    }
  }

  Future<void> _verifyPhoneNumber() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _linkUser(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() { 
              _errorMessage = e.message ?? 'SMS Verification failed'; 
              _isLoading = false; 
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showOtpDialog(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initiate phone verification. Check your phone number format (e.g. +1234567890).';
          _isLoading = false;
        });
      }
    }
  }

  void _showOtpDialog(String verificationId) {
    final otpController = TextEditingController();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter SMS Verification Code'),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '6-digit code',
            prefixIcon: Icon(Icons.password),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isLoading = false);
            }, 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: otpController.text.trim(),
                );
                await _linkUser(credential);
              } catch (e) {
                if (mounted) {
                  setState(() { 
                    _errorMessage = 'Invalid SMS Code provided.'; 
                    _isLoading = false; 
                  });
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkUser(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Firebase success, register user in local Hive DB
      final authService = ref.read(authServiceProvider);
      final success = await authService.signUp(
        _usernameController.text.trim(),
        _passwordController.text,
        _enableBiometrics,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (success && mounted) {
        if (_enableBiometrics) {
           await authService.authenticateWithBiometrics();
        }
        if (!mounted) return;
        context.go('/');
      } else {
        if (mounted) {
          setState(() { 
            _errorMessage = 'Username already taken or local registration failed.'; 
            _isLoading = false; 
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _errorMessage = e.toString(); 
          _isLoading = false; 
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'Tactical Medic Login' : 'Create Medic Account',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin 
                        ? 'Enter your credentials to access patient records.'
                        : 'Secure your offline data with a new verified account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!_isLogin) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v!.isEmpty ? 'Req' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                            ),
                            validator: (v) => v!.isEmpty ? 'Req' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (e.g. +1234567890)',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) => v!.isEmpty || !v.startsWith('+') 
                          ? 'Valid Phone format (+xxx) required' 
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v!.length < 4 ? 'Min 4 characters required' : null,
                  ),
                  
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CheckboxListTile(
                        title: const Text('Register Fingerprint', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Capture biometrics for fast access.'),
                        secondary: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary, size: 32),
                        value: _enableBiometrics,
                        onChanged: (val) {
                          setState(() => _enableBiometrics = val ?? true);
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  _isLoading 
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          if (_isLogin) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _submitForm,
                                      child: const Text('SECURE LOGIN'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  height: 56,
                                  width: 56,
                                  child: ElevatedButton(
                                    onPressed: _checkBiometrics,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                      elevation: 0,
                                    ),
                                    child: const Icon(Icons.fingerprint, size: 32),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                child: const Text('VERIFY & CREATE ACCOUNT'),
                              ),
                            ),
                          ],
                        ]
                      ),
                      
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = '';
                      });
                    },
                    child: Text(_isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
