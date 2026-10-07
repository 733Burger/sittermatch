import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  final String selectedRole;

  const SignupScreen({super.key, required this.selectedRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Helper class to ensure the role selected by the user is correctly formatted for backend API calls.
  String _getBackendRole(String displayRole) {
    return displayRole.toUpperCase() == 'SITTER' ? 'SITTER' : 'HOMEOWNER';
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear focus from keyboard 
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signup(
        fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _getBackendRole(widget.selectedRole),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Account created successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Signup failed. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not connect to the server. Please check your network connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = AppColors.background;
    const cardColor = Colors.white;
    const primaryDark = AppColors.darkText;
    const primaryTeal = AppColors.primaryRust;
    const subtextColor = Colors.black54;
    const inputFillColor = AppColors.expandButtonBg;
    const borderColor = Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryDark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Updated Logo to match the Teal Paw
                  const Icon(Icons.pets, size: 44, color: primaryTeal),
                  const SizedBox(height: 8),
                  const Text(
                    'SIT & STAY',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create your account to get started.',
                    style: TextStyle(color: subtextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Card Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Title & Selected Role Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6, 
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightRustBg, 
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.selectedRole,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'First Name:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _firstNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: 'First name...',
                                      hintStyle: const TextStyle(color: subtextColor, fontSize: 14),
                                      fillColor: inputFillColor,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12), // Softer corners
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'First name is required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Name:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _lastNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: 'Last name...',
                                      hintStyle: const TextStyle(color: subtextColor, fontSize: 14),
                                      fillColor: inputFillColor,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12), // Softer corners
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'Second name is required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Email
                        const Text(
                          'Email:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Enter your email address...',
                            hintStyle: const TextStyle(color: subtextColor, fontSize: 14),
                            fillColor: inputFillColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone Number
                        const Text(
                          'Phone Number:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Enter phone number...',
                            hintStyle: const TextStyle(color: subtextColor, fontSize: 14),
                            fillColor: inputFillColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Phone number is required';
                            if (!RegExp(r'^[0-9+\-\s()]{7,15}$').hasMatch(v.trim())) {
                              return 'Enter a valid phone number (7 to 15 digits)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password
                        const Text(
                          'Password:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Enter a password...',
                            hintStyle: const TextStyle(color: subtextColor, fontSize: 14),
                            fillColor: inputFillColor,
                            filled: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hidePassword ? Icons.visibility_off : Icons.visibility,
                                color: subtextColor,
                              ),
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), // Softer corners
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'Password must be at least 8 characters'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        const Text(
                          'Confirm Password:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _hideConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSignup(),
                          decoration: InputDecoration(
                            hintText: 'Re-enter your password...',
                            hintStyle: const TextStyle(color: subtextColor, fontSize: 14),
                            fillColor: inputFillColor,
                            filled: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: subtextColor,
                              ),
                              onPressed: () =>
                                  setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), // Softer corners
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) =>
                              v != _passwordController.text ? 'Passwords do not match' : null,
                        ),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _loading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}