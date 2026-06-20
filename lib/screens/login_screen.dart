import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerBusinessNameController = TextEditingController();

  final _serverUrlController = TextEditingController();

  bool _isRegisterMode = false;
  bool _showServerConfig = false;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await ApiClient().getBaseUrl();
    setState(() {
      _serverUrlController.text = url;
    });
  }

  Future<void> _saveServerUrl() async {
    final url = _serverUrlController.text.trim();
    if (url.isNotEmpty) {
      await ApiClient().setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server API URL updated to: $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerBusinessNameController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = false;
    if (_isRegisterMode) {
      success = await authProvider.register({
        'username': _registerUsernameController.text.trim(),
        'email': _registerEmailController.text.trim(),
        'password': _registerPasswordController.text,
        'businessName': _registerBusinessNameController.text.trim(),
        'role': 'Manager', // Default sign up role
      });
    } else {
      success = await authProvider.login(
        _loginUsernameController.text.trim(),
        _loginPasswordController.text,
      );
    }

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error Occurred'),
            content: Text(authProvider.error ?? 'An unexpected error occurred.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Branding
                    const Icon(
                      Icons.payments_outlined,
                      size: 60,
                      color: Color(0xFF006A61),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'SmartBill Pro',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B1C30),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Point-of-Sale Mobile Terminal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF7C839B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24), // Reduced from 32

                  // Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRegisterMode = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_isRegisterMode ? const Color(0xFF006A61) : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: !_isRegisterMode ? const Color(0xFF006A61) : const Color(0xFF7C839B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRegisterMode = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _isRegisterMode ? const Color(0xFF006A61) : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            child: Text(
                              'Register Business',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: _isRegisterMode ? const Color(0xFF006A61) : const Color(0xFF7C839B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Reduced from 24

                  // Form Fields
                  if (!_isRegisterMode) ...[
                    CustomTextField(
                      controller: _loginUsernameController,
                      label: 'Username',
                      placeholder: 'Enter username',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _loginPasswordController,
                      label: 'Password',
                      placeholder: 'Enter password',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    CustomTextField(
                      controller: _registerUsernameController,
                      label: 'Username',
                      placeholder: 'Choose username',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _registerEmailController,
                      label: 'Email Address',
                      placeholder: 'name@business.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _registerBusinessNameController,
                      label: 'Business Name',
                      placeholder: 'e.g. SmartSalon Main Branch',
                      prefixIcon: Icons.business_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _registerPasswordController,
                      label: 'Password',
                      placeholder: 'Set secure password',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: _isRegisterMode ? 'Establish Brand' : 'Access Account',
                    isLoading: authProvider.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),

                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C839B),
                    ),
                    onPressed: () {
                      setState(() {
                        _showServerConfig = !_showServerConfig;
                      });
                    },
                    icon: const Icon(Icons.settings_ethernet, size: 16),
                    label: Text(
                      _showServerConfig ? 'Hide Server Parameters' : 'Configure Server Endpoint',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),

                  // Server Config HUD
                  if (_showServerConfig) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _serverUrlController,
                            label: 'Server API Endpoint',
                            placeholder: 'https://e071-2401-4900-882d-e15c-753e-6498-b2f2-c2f0.ngrok-free.app/api',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF006A61),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFC6C6CD)),
                              ),
                            ),
                            onPressed: _saveServerUrl,
                            child: const Text('Update Base API URL'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Defaults: \n- Ngrok Tunnel: https://e071-2401-4900-882d-e15c-753e-6498-b2f2-c2f0.ngrok-free.app/api',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7C839B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
