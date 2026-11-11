import 'package:flutter/material.dart';

import 'dashboard/dashboard_screen.dart';
import 'screens/create_account_screen.dart';
import 'services/api_service.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartDairyApp());
}

class SmartDairyApp extends StatelessWidget {
  const SmartDairyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeModeNotifier,
          builder: (context, currentThemeMode, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Smart Dairy'.tr,
              theme: ThemeService.lightTheme,
              darkTheme: ThemeService.darkTheme,
              themeMode: currentThemeMode,
              home: const AppAuthGate(),
            );
          },
        );
      },
    );
  }
}

class AppAuthGate extends StatelessWidget {
  const AppAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. If valid session exists, restore securely and open dashboard
    if (ApiService.restoreSession()) {
      return const DashboardScreen();
    }

    // 2. On fresh install (no account created yet), show Create Account screen first
    if (!ApiService.hasCreatedAccount()) {
      return const CreateAccountScreen();
    }

    // 3. For returning users, display Login screen
    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  final String? prefilledUsername;
  final String? prefilledRole;

  const LoginPage({super.key, this.prefilledUsername, this.prefilledRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'DAIRY_OWNER';
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.prefilledUsername ?? '');
    if (widget.prefilledRole != null && widget.prefilledRole!.isNotEmpty) {
      _selectedRole = widget.prefilledRole!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<void> _login() async {
    setState(() => _loginError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      // Connect to Spring Boot JWT Backend and validate role
      final data = await ApiService.login(
        username,
        password,
        role: _selectedRole,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected: ${data['fullName'] ?? username} (${data['role'] ?? _selectedRole})',
          ),
          backgroundColor: const Color(0xFF087F73),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() => _isLoading = false);

      // Open Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showServerConfigDialog() {
    final hostController = TextEditingController(text: ApiService.serverHost);
    bool isTesting = false;
    Map<String, dynamic>? pingResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.dns_rounded, color: Color(0xFF087F73)),
              SizedBox(width: 8),
              Text(
                'Server Endpoint & Ping',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect multiple devices (Owner and Members) to the shared Spring Boot backend over the network:',
                style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: 'Host IP & Port',
                  hintText: 'e.g., 10.186.234.201:8080',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text(
                      'Emulator (10.0.2.2:8080)',
                      style: TextStyle(fontSize: 10.5),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        hostController.text = '10.0.2.2:8080';
                        pingResult = null;
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text(
                      'Wi-Fi Mobile (10.186.234.201:8080)',
                      style: TextStyle(fontSize: 10.5),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        hostController.text = '10.186.234.201:8080';
                        pingResult = null;
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text(
                      'Localhost (localhost:8080)',
                      style: TextStyle(fontSize: 10.5),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        hostController.text = 'localhost:8080';
                        pingResult = null;
                      });
                    },
                  ),
                ],
              ),
              if (pingResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pingResult!['success'] == true ? const Color(0xFFE7F6F3) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pingResult!['success'] == true ? const Color(0xFF087F73) : const Color(0xFFF59E0B),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pingResult!['success'] == true ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 16,
                        color: pingResult!['success'] == true ? const Color(0xFF087F73) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pingResult!['message'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pingResult!['success'] == true ? const Color(0xFF087F73) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: isTesting
                  ? null
                  : () async {
                      setDialogState(() => isTesting = true);
                      final res = await ApiService.testServerConnection(hostController.text);
                      setDialogState(() {
                        isTesting = false;
                        pingResult = res;
                      });
                    },
              child: isTesting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Test Ping'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087F73),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ApiService.setServerHost(hostController.text);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Server host configured to: ${ApiService.serverHost}',
                    ),
                    backgroundColor: const Color(0xFF087F73),
                  ),
                );
              },
              child: const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }



  // ------------------------------------------------------------
  // LOGIN PAGE
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // LOGO
                    _buildLogo(),

                    const SizedBox(height: 28),

                    // WELCOME
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14213D),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Sign in to manage your dairy center',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF718096)),
                    ),

                    const SizedBox(height: 30),

                    // LOGIN CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF14213D),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // API Error Banner
                          if (_loginError != null) ...[
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
                                      _loginError!,
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

                          // ROLE SELECTOR
                          const Text(
                            'Select Role *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344054),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF087F73), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF087F73), width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'DAIRY_OWNER', child: Text('Owner')),
                              DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                              DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),

                          const SizedBox(height: 18),

                          // USERNAME LABEL
                          const Text(
                            'Username',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344054),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // USERNAME
                          TextFormField(
                            controller: _usernameController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hint: 'Enter username',
                              icon: Icons.person_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your username';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // PASSWORD LABEL
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344054),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // PASSWORD
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: _inputDecoration(
                              hint: 'Enter password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF7A869A),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }

                              if (value.length < 6) {
                                return 'Password must contain at least 6 characters';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          // REMEMBER ME
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF087F73),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Remember me',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF087F73),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF8DBBB5,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // LINK: New user? Create Account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New user?'.tr,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                                  );
                                },
                                child: Text(
                                  'Create Account'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF087F73),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),

                          // SERVER ENDPOINT SELECTOR
                          InkWell(
                            onTap: _showServerConfigDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.dns_outlined,
                                    size: 15,
                                    color: Color(0xFF087F73),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Backend: http://${ApiService.serverHost}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.settings_outlined,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // SECURITY MESSAGE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          size: 17,
                          color: Color(0xFF087F73),
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Secure login with JWT authentication',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // APP NAME
                    const Text(
                      'Smart Dairy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF14213D),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Milk Collection & Dairy Management',
                      style: TextStyle(fontSize: 11, color: Color(0xFF98A2B3)),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOGO
  // ------------------------------------------------------------

  Widget _buildLogo() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087F73).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F6F3),
              shape: BoxShape.circle,
            ),
          ),

          const Icon(
            Icons.water_drop_rounded,
            size: 42,
            color: Color(0xFF087F73),
          ),

          const Positioned(
            bottom: 20,
            child: Icon(
              Icons.grass_rounded,
              size: 16,
              color: Color(0xFF55B99C),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD DESIGN
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),

      prefixIcon: Icon(icon, color: const Color(0xFF087F73), size: 21),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: const Color(0xFFF8FAFA),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF087F73), width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
