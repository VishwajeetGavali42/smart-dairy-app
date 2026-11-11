import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/validation_utils.dart';

import '../main.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../screens/audit_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const ProfileScreen({super.key, this.onBackToDashboard});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color secondaryText = Color(0xFF7A869A);
  static const Color background = Color(0xFFF8FAFA);

  String _dairyName = 'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur';
  String _ownerName = 'Vishwajeet Shinde';
  String _phone = '+91 98220 12345';
  final String _centerCode = 'LDK-402';
  String _address = 'Kadamwadi, Kolhapur, Maharashtra';

  String _currentShift = 'Morning';
  bool _autoPrintReceipts = true;
  bool _smsAlerts = true;
  bool _soundOnEntry = true;
  String get _appLanguage => LanguageService.currentLanguage;

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _dairyName);
    final ownerController = TextEditingController(text: _ownerName);
    final phoneController = TextEditingController(text: _phone);
    final addressController = TextEditingController(text: _address);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Edit Dairy Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogTextField(
                  nameController,
                  'Dairy Center Name',
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                ),
                const SizedBox(height: 12),
                _dialogTextField(
                  ownerController,
                  'Owner / Manager Name',
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                ),
                const SizedBox(height: 12),
                _dialogTextField(
                  phoneController,
                  'Contact Number',
                  inputFormatters: ValidationUtils.phoneFormatter,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _dialogTextField(addressController, 'Address'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  _dairyName = nameController.text.trim();
                  _ownerName = ownerController.text.trim();
                  _phone = phoneController.text.trim();
                  _address = addressController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dairy profile updated successfully'),
                    backgroundColor: primary,
                  ),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogTextField(
    TextEditingController controller,
    String label, {
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: secondaryText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  void _showShiftSwitchDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Switch Active Shift',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose current milk collection shift',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.orange,
                  ),
                  title: const Text('Morning Shift (06:00 AM - 10:00 AM)'),
                  trailing: _currentShift == 'Morning'
                      ? const Icon(Icons.check_circle_rounded, color: primary)
                      : null,
                  onTap: () {
                    setState(() => _currentShift = 'Morning');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.nights_stay_rounded,
                    color: Colors.indigo,
                  ),
                  title: const Text('Evening Shift (05:00 PM - 09:00 PM)'),
                  trailing: _currentShift == 'Evening'
                      ? const Icon(Icons.check_circle_rounded, color: primary)
                      : null,
                  onTap: () {
                    setState(() => _currentShift = 'Evening');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContactAdminDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact App Admin / Developer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                        Text(
                          'Developer Vishwajeet (Full Access)',
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  'If the dairy owner is facing any problem with milk collection, rates, 10-day cycle billing, deductions, or sync, Developer Vishwajeet has full access to diagnose and resolve it.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.blue,
                ),
                title: const Text('Direct Phone: +91 98220 12345'),
                subtitle: const Text('Available for owner technical support'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Calling Developer Vishwajeet (+91 98220 12345)...',
                        ),
                        backgroundColor: primary,
                      ),
                    );
                  },
                  child: const Text('Call'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700, color: darkText),
          ),
          content: const Text(
            'Are you sure you want to log out from Smart Dairy?',
            style: TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ApiService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            leading: widget.onBackToDashboard != null
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: darkText,
                    ),
                    onPressed: widget.onBackToDashboard,
                  )
                : (Navigator.canPop(context)
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: darkText,
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile & Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                Text(
                  'Manage your dairy center details',
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: primary),
                tooltip: 'Edit Profile',
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =======================================================
                // DAIRY HERO CARD
                // =======================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF087F73), Color(0xFF0C9B8D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 34,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dairyName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _centerCode,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ApiService.userRole.toUpperCase() == 'ADMIN'
                                      ? 'Role: System Admin & Lead Developer (Vishwajeet)'
                                      : 'Manager: $_ownerName',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _phone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =======================================================
                // ACTIVE SHIFT BAR
                // =======================================================
                _sectionHeader('Current Operations'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _currentShift == 'Morning'
                              ? const Color(0xFFFFF4DF)
                              : const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _currentShift == 'Morning'
                              ? Icons.wb_sunny_rounded
                              : Icons.nights_stay_rounded,
                          color: _currentShift == 'Morning'
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Collection Shift',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Currently recording $_currentShift collections',
                              style: const TextStyle(
                                fontSize: 11,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _showShiftSwitchDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: const BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Switch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =======================================================
                // APP PREFERENCES
                // =======================================================
                _sectionHeader('Dairy Preferences'),
                const SizedBox(height: 10),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E9E8)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _autoPrintReceipts,
                        activeThumbColor: primary,
                        activeTrackColor: primary.withValues(alpha: 0.3),
                        title: const Text(
                          'Auto-Print Slip on Collection',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        subtitle: const Text(
                          'Send digital receipt command after save',
                          style: TextStyle(fontSize: 11, color: secondaryText),
                        ),
                        onChanged: (val) {
                          setState(() => _autoPrintReceipts = val);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      SwitchListTile(
                        value: _smsAlerts,
                        activeThumbColor: primary,
                        activeTrackColor: primary.withValues(alpha: 0.3),
                        title: const Text(
                          'SMS / WhatsApp Farmer Alerts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        subtitle: const Text(
                          'Notify farmers after each milk drop',
                          style: TextStyle(fontSize: 11, color: secondaryText),
                        ),
                        onChanged: (val) {
                          setState(() => _smsAlerts = val);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      SwitchListTile(
                        value: _soundOnEntry,
                        activeThumbColor: primary,
                        activeTrackColor: primary.withValues(alpha: 0.3),
                        title: const Text(
                          'Sound Chime on Entry',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        subtitle: const Text(
                          'Audio confirmation when entry is added',
                          style: TextStyle(fontSize: 11, color: secondaryText),
                        ),
                        onChanged: (val) {
                          setState(() => _soundOnEntry = val);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      SwitchListTile(
                        value: ThemeService.isDarkMode,
                        activeThumbColor: primary,
                        activeTrackColor: primary.withValues(alpha: 0.3),
                        title: Text(
                          'Dark Mode Theme'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        subtitle: Text(
                          'Toggle dark slate theme mode'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: secondaryText,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            ThemeService.setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =======================================================
                // SYSTEM & SUPPORT
                // =======================================================
                _sectionHeader('System & Support'),
                const SizedBox(height: 10),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E9E8)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _actionTile(
                        icon: Icons.language_rounded,
                        title: 'App Language',
                        subtitle: _appLanguage,
                        onTap: () {
                          _showLanguageDialog();
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      _actionTile(
                        icon: Icons.cloud_sync_outlined,
                        title: 'Data Backup & Sync',
                        subtitle: 'Last synced: Today at 02:45 PM',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All records synced with cloud server.',
                              ),
                              backgroundColor: primary,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      if (ApiService.userRole.toUpperCase() != 'MEMBER' && ApiService.userRole.toUpperCase() != 'EMPLOYEE')
                        ...[
                          _actionTile(
                            icon: Icons.history_edu_rounded,
                            title: 'Audit Trail & Edits Log',
                            subtitle: 'Inspect financial & collection audit history',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuditHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFEEF1F0)),
                        ],
                      _actionTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Contact App Admin / Developer',
                        subtitle: 'Developer Vishwajeet (+91 98220 12345)',
                        onTap: () {
                          _showContactAdminDialog();
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      _actionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Customer Support',
                        subtitle: 'Call: 1800-200-DAIRY',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Toll-free Dairy helpline: 1800-200-3247',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEF1F0)),
                      _actionTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About Smart Dairy',
                        subtitle: 'Version 1.0.0 (Build 2026)',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Smart Dairy',
                            applicationVersion: '1.0.0+1',
                            applicationIcon: const Icon(
                              Icons.water_drop_rounded,
                              size: 38,
                              color: primary,
                            ),
                            children: const [
                              Text(
                                'Smart Dairy management system designed for milk collection centers, rate charts, invoicing, and member accounts.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // =======================================================
                // LOGOUT BUTTON
                // =======================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: secondaryText),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFF98A2B3),
      ),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Select Language'.tr),
          children: ['English', 'Marathi (मराठी)', 'Hindi (हिंदी)'].map((lang) {
            return SimpleDialogOption(
              onPressed: () {
                LanguageService.setLanguage(lang);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang.contains('Marathi')
                          ? 'भाषा बदलली: मराठी'
                          : (lang.contains('Hindi')
                                ? 'भाषा बदली गई: हिंदी'
                                : 'Language changed: English'),
                    ),
                    backgroundColor: primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  lang,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _appLanguage == lang
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _appLanguage == lang ? primary : darkText,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E9E8)),
    );
  }
}
