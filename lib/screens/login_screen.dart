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

  // Login Controllers
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register Controllers - Step 1: Account Setup
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  // Register Controllers - Step 2: Business Branding
  final _registerLegalNameController = TextEditingController();
  final _registerTradingNameController = TextEditingController();
  final _registerWebsiteController = TextEditingController();
  final _registerLogoUrlController = TextEditingController();

  // Register Controllers - Step 3: Contact Channels
  final _registerBusinessPhoneController = TextEditingController();
  final _registerBusinessEmailController = TextEditingController();
  final _registerGstInController = TextEditingController();

  // Register Controllers - Step 4: Location & Tax Config
  final _registerAddressController = TextEditingController();
  final _registerCityController = TextEditingController();
  final _registerStateController = TextEditingController();
  final _registerPostalCodeController = TextEditingController();

  double _registerDefaultTaxRate = 18.0;
  bool _registerPricesIncludeTax = true;

  int _registerStep = 1;

  final _serverUrlController = TextEditingController();

  bool _isRegisterMode = false;
  bool _showServerConfig = false;
  bool _isCheckingAvailability = false;

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
    _registerLegalNameController.dispose();
    _registerTradingNameController.dispose();
    _registerWebsiteController.dispose();
    _registerLogoUrlController.dispose();
    _registerBusinessPhoneController.dispose();
    _registerBusinessEmailController.dispose();
    _registerGstInController.dispose();
    _registerAddressController.dispose();
    _registerCityController.dispose();
    _registerStateController.dispose();
    _registerPostalCodeController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  bool _validateRegisterStep(int step) {
    if (step == 1) {
      final username = _registerUsernameController.text.trim();
      if (username.isEmpty) {
        _showError('Username is required');
        return false;
      }
      if (username.length < 3) {
        _showError('Username must be at least 3 characters');
        return false;
      }
      final email = _registerEmailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _showError('Please enter a valid email address');
        return false;
      }
      final password = _registerPasswordController.text;
      if (password.isEmpty || password.length < 6) {
        _showError('Password must be at least 6 characters');
        return false;
      }
    } else if (step == 2) {
      final legalName = _registerLegalNameController.text.trim();
      if (legalName.isEmpty) {
        _showError('Business Legal Name is required');
        return false;
      }
    } else if (step == 3) {
      final phone = _registerBusinessPhoneController.text.trim();
      if (phone.isEmpty) {
        _showError('Business Phone Number is required');
        return false;
      }
    } else if (step == 4) {
      final address = _registerAddressController.text.trim();
      if (address.isEmpty) {
        _showError('Street Address is required');
        return false;
      }
      final city = _registerCityController.text.trim();
      if (city.isEmpty) {
        _showError('City is required');
        return false;
      }
      final state = _registerStateController.text.trim();
      if (state.isEmpty) {
        _showError('State is required');
        return false;
      }
      final pin = _registerPostalCodeController.text.trim();
      if (pin.isEmpty) {
        _showError('PIN / Postal Code is required');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isRegisterMode) {
      if (_registerStep < 4) {
        if (_validateRegisterStep(_registerStep)) {
          if (_registerStep == 1) {
            setState(() {
              _isCheckingAvailability = true;
            });
            try {
              final username = _registerUsernameController.text.trim();
              final email = _registerEmailController.text.trim();
              final usernameExists = await authProvider.checkUsernameExists(username);
              if (usernameExists) {
                _showError('Username is already taken');
                setState(() {
                  _isCheckingAvailability = false;
                });
                return;
              }
              final emailExists = await authProvider.checkEmailExists(email);
              if (emailExists) {
                _showError('Email is already registered');
                setState(() {
                  _isCheckingAvailability = false;
                });
                return;
              }
            } catch (e) {
              _showError('Verification failed: $e');
              setState(() {
                _isCheckingAvailability = false;
              });
              return;
            }
            setState(() {
              _isCheckingAvailability = false;
            });
          }
          setState(() {
            _registerStep++;
          });
        }
        return;
      }

      if (!_validateRegisterStep(4)) return;

      bool success = await authProvider.register({
        'username': _registerUsernameController.text.trim(),
        'email': _registerEmailController.text.trim(),
        'password': _registerPasswordController.text,
        'role': 'Owner',
        'legalName': _registerLegalNameController.text.trim(),
        'tradingName': _registerTradingNameController.text.trim().isNotEmpty
            ? _registerTradingNameController.text.trim()
            : _registerLegalNameController.text.trim(),
        'businessPhone': _registerBusinessPhoneController.text.trim(),
        'businessAddress': _registerAddressController.text.trim(),
        'businessCity': _registerCityController.text.trim(),
        'businessState': _registerStateController.text.trim(),
        'businessPostalCode': _registerPostalCodeController.text.trim(),
        'businessCountry': 'India',
        'gstIn': _registerGstInController.text.trim().isNotEmpty ? _registerGstInController.text.trim() : null,
        'logoUrl': _registerLogoUrlController.text.trim().isNotEmpty ? _registerLogoUrlController.text.trim() : null,
        'website': _registerWebsiteController.text.trim().isNotEmpty ? _registerWebsiteController.text.trim() : null,
        'businessEmail': _registerBusinessEmailController.text.trim().isNotEmpty
            ? _registerBusinessEmailController.text.trim()
            : _registerEmailController.text.trim(),
        'defaultTaxRate': _registerDefaultTaxRate,
        'pricesIncludeTax': _registerPricesIncludeTax,
      });

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Registration Failed'),
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
    } else {
      if (!_formKey.currentState!.validate()) return;

      bool success = await authProvider.login(
        _loginUsernameController.text.trim(),
        _loginPasswordController.text,
      );

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
  }

  Widget _buildStepIndicator() {
    final steps = [
      {'label': 'Account', 'icon': Icons.security},
      {'label': 'Branding', 'icon': Icons.business},
      {'label': 'Contact', 'icon': Icons.phone},
      {'label': 'Tax & Loc', 'icon': Icons.map},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Step $_registerStep of 4 · ${steps[_registerStep - 1]['label']}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006A61),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 15,
                right: 15,
                child: Container(
                  height: 2,
                  color: const Color(0xFFEFF4FF),
                ),
              ),
              Positioned(
                left: 15,
                right: 15,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final activeWidth = width * ((_registerStep - 1) / 3);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 2,
                        width: activeWidth,
                        color: const Color(0xFF006A61),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final stepNum = index + 1;
                  final isActive = _registerStep == stepNum;
                  final isCompleted = _registerStep > stepNum;

                  return GestureDetector(
                    onTap: () {
                      if (stepNum < _registerStep) {
                        setState(() {
                          _registerStep = stepNum;
                        });
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF006A61)
                            : isCompleted
                                ? const Color(0xFFEFF4FF)
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isActive || isCompleted)
                              ? const Color(0xFF006A61)
                              : const Color(0xFFC6C6CD),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 12, color: Color(0xFF006A61))
                            : Text(
                                '$stepNum',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF7C839B),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _registerUsernameController,
          label: 'Owner Username',
          placeholder: 'e.g. john_doe',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerEmailController,
          label: 'Owner Personal Email',
          placeholder: 'john@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerPasswordController,
          label: 'Security Password',
          placeholder: 'Min 6 characters',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.password],
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) {
            if (_validateRegisterStep(1)) {
              setState(() {
                _registerStep = 2;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep2Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _registerLegalNameController,
          label: 'Business Legal Name',
          placeholder: 'Acme Enterprises Ltd',
          prefixIcon: Icons.business,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.organizationName],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerTradingNameController,
          label: 'Brand/Trading Name (Optional)',
          placeholder: 'Acme Salon',
          prefixIcon: Icons.storefront,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerWebsiteController,
          label: 'Website URL (Optional)',
          placeholder: 'https://www.acmesalon.com',
          prefixIcon: Icons.language,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerLogoUrlController,
          label: 'Business Logo Image URL (Optional)',
          placeholder: 'https://acme.com/assets/logo.png',
          prefixIcon: Icons.image_outlined,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onFieldSubmitted: (_) {
            if (_validateRegisterStep(2)) {
              setState(() {
                _registerStep = 3;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep3Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _registerBusinessPhoneController,
          label: 'Business Phone Number',
          placeholder: '+91 99887 76655',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerBusinessEmailController,
          label: 'Business Email (Optional)',
          placeholder: 'support@acmesalon.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerGstInController,
          label: 'GSTIN Tax Registration Code (Optional)',
          placeholder: '36AAAAA1111A1Z1',
          prefixIcon: Icons.tag,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onFieldSubmitted: (_) {
            if (_validateRegisterStep(3)) {
              setState(() {
                _registerStep = 4;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep4Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _registerAddressController,
          label: 'Headquarters Street Address',
          placeholder: 'Suite 101, Business Park',
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.streetAddressLine1],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerCityController,
          label: 'City',
          placeholder: 'Hyderabad',
          prefixIcon: Icons.location_city_outlined,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.addressCity],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerStateController,
          label: 'State',
          placeholder: 'Telangana',
          prefixIcon: Icons.map_outlined,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.addressState],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _registerPostalCodeController,
          label: 'PIN Code',
          placeholder: '500001',
          prefixIcon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.postalCode],
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        Text(
          'DEFAULT TAX CONTRIBUTION',
          style: GoogleFonts.inter(
            color: const Color(0xFF7C839B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC6C6CD)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: _registerDefaultTaxRate,
              isExpanded: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B1C30),
              ),
              items: const [
                DropdownMenuItem(value: 18.0, child: Text('18.0% Standard GST Rule')),
                DropdownMenuItem(value: 5.0, child: Text('5.0% Beauty & Food Services')),
                DropdownMenuItem(value: 0.0, child: Text('0.0% Tax Exempt Rule')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _registerDefaultTaxRate = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _registerPricesIncludeTax,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _registerPricesIncludeTax = val;
              });
            }
          },
          title: Text(
            'Catalog prices include GST contributions',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B1C30),
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF006A61),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                      const SizedBox(height: 24),
  
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
                      const SizedBox(height: 20),
  
                      // Form Fields
                      if (!_isRegisterMode) ...[
                        CustomTextField(
                          controller: _loginUsernameController,
                          label: 'Username',
                          placeholder: 'Enter username',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          enableSuggestions: false,
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
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          autocorrect: false,
                          enableSuggestions: false,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Access Account',
                          isLoading: authProvider.isLoading,
                          onPressed: _submit,
                        ),
                      ] else ...[
                        _buildStepIndicator(),
                        if (_registerStep == 1) _buildStep1Fields(),
                        if (_registerStep == 2) _buildStep2Fields(),
                        if (_registerStep == 3) _buildStep3Fields(),
                        if (_registerStep == 4) _buildStep4Fields(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_registerStep > 1) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFC6C6CD)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _registerStep--;
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF45464D)),
                                  label: Text(
                                    'Back',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF45464D),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: 2,
                              child: CustomButton(
                                text: _registerStep < 4
                                    ? 'Continue'
                                    : 'Complete Setup',
                                isLoading: authProvider.isLoading || _isCheckingAvailability,
                                onPressed: _submit,
                                icon: Icons.arrow_forward,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                                placeholder: 'https://4265-2401-4900-882d-e15c-39ba-a63b-944e-b565.ngrok-free.app/api',
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
                                'Defaults: \n- Ngrok Tunnel: https://4265-2401-4900-882d-e15c-39ba-a63b-944e-b565.ngrok-free.app/api',
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
      ),
    );
  }
}
