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
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
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
        if (username.toLowerCase() == 'admin') {
          context.go('/admin');
        } else {
          context.go('/');
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password.';
          _isLoading = false;
        });
      }
    } else {
      if (username.toLowerCase() == 'admin') {
        setState(() {
          _errorMessage = 'Cannot register as admin. Use login.';
          _isLoading = false;
        });
        return;
      }
      
      final success = await authService.signUp(username, password, _enableBiometrics);
      if (success && mounted) {
        context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Username already exists.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                        : 'Secure your offline data with a new account.',
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

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
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
                    CheckboxListTile(
                      title: const Text('Enable Fast Biometric Login'),
                      value: _enableBiometrics,
                      onChanged: (val) {
                        setState(() => _enableBiometrics = val ?? true);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  _isLoading 
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          child: Text(_isLogin ? 'SECURE LOGIN' : 'CREATE ACCOUNT'),
                        ),
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
