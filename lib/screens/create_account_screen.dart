import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../main_smartdairy_backup.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _adminKeyController = TextEditingController();
  final TextEditingController _memberCodeController = TextEditingController();

  String _selectedRole = 'DAIRY_OWNER'; // 'DAIRY_OWNER', 'MEMBER', 'ADMIN'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _apiErrorMessage;

  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color secondaryText = Color(0xFF64748B);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _adminKeyController.dispose();
    _memberCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    setState(() => _apiErrorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() => _apiErrorMessage = 'Password and Confirm Password do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.register(
        username: _usernameController.text.trim(),
        password: password,
        confirmPassword: confirmPassword,
        role: _selectedRole,
        fullName: _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        memberCode: _selectedRole == 'MEMBER' && _memberCodeController.text.trim().isNotEmpty
            ? _memberCodeController.text.trim().toUpperCase()
            : null,
        adminSecretKey: _selectedRole == 'ADMIN' ? _adminKeyController.text.trim() : null,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully for ${_usernameController.text.trim()}! Please login.'.tr),
          backgroundColor: primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to Login screen with pre-filled credentials
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            prefilledUsername: _usernameController.text.trim(),
            prefilledRole: _selectedRole,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _apiErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Logo & Title
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'AI Assisted Smart Dairy'.tr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Create New Account'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Register to access dairy operations and milk records'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // API Error Banner
                  if (_apiErrorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _apiErrorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Card Container for Form Fields
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role Dropdown
                        Text(
                          'Select Role *'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_rounded, color: primary, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'DAIRY_OWNER',
                              child: Text('Owner (Dairy Collection Center)'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'MEMBER',
                              child: Text('Member (Farmer / Supplier)'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text('Admin (System Developer)'.tr),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRole = val);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Username
                        Text(
                          'Username *'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'e.g., ramesh_patil'.tr,
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: primary, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Username is required'.tr;
                            }
                            if (val.trim().length < 3) {
                              return 'Username must be at least 3 characters'.tr;
                            }
                            if (val.contains(' ')) {
                              return 'Username cannot contain spaces'.tr;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        Text(
                          'Password *'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Minimum 6 characters'.tr,
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: secondaryText,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Password is required'.tr;
                            }
                            if (val.length < 6) {
                              return 'Password must be at least 6 characters'.tr;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Confirm Password
                        Text(
                          'Confirm Password *'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Re-enter your password'.tr,
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: secondaryText,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please confirm your password'.tr;
                            }
                            if (val != _passwordController.text) {
                              return 'Passwords do not match'.tr;
                            }
                            return null;
                          },
                        ),

                        // Dynamic role specific fields:
                        // If Admin role: Require Admin Authorization Key
                        if (_selectedRole == 'ADMIN') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.security_rounded, color: Color(0xFF1D4ED8), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Privileged Admin role: Authorized Master Setup Key required to prevent unauthorized elevation.'.tr,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Admin Authorization Key *'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _adminKeyController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Enter Admin authorization code'.tr,
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF1D4ED8), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primary, width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (val) {
                              if (_selectedRole == 'ADMIN' && (val == null || val.trim().isEmpty)) {
                                return 'Admin Authorization Key is required'.tr;
                              }
                              return null;
                            },
                          ),
                        ],

                        // If Member role: Member Code
                        if (_selectedRole == 'MEMBER') ...[
                          const SizedBox(height: 16),
                          Text(
                            'Farmer / Member Code (Owner-Issued Code)'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your Dairy-issued Farmer Code (e.g., M001) to link your milk records. You can also leave this blank and link it later.'.tr,
                            style: const TextStyle(fontSize: 11, color: secondaryText),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _memberCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g., M001 (Leave empty to link later)'.tr,
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.tag_rounded, color: primary, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primary, width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: primary.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Create Account'.tr,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Link to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?'.tr,
                        style: const TextStyle(fontSize: 14, color: secondaryText),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: Text(
                          'Login'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
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
