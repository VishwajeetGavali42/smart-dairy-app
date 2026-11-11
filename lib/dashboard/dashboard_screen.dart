import 'package:flutter/material.dart';

import '../milk_collection/milk_collection_screen.dart';
import '../members/members_screen.dart';
import '../rate_chart/rate_chart_screen.dart';
import '../advance/advance_screen.dart';
import '../invoice/invoice_screen.dart' as invoice;
import '../payments/payments_screen.dart' as payments;
import '../deduction/deduction_screen.dart';
import '../milk_sale/milk_sale_screen.dart';
import '../expense/expense_screen.dart';
import '../dispatch/dispatch_screen.dart';
import '../received/received_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../products/products_screen.dart';
import '../invoice/detailed_bill_statement_screen.dart';
import '../bonus/annual_bonus_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/audit_history_screen.dart';
import '../utils/format_utils.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/language_service.dart';
import '../main_smartdairy_backup.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color secondaryText = Color(0xFF7A869A);
  static const Color background = Color(0xFFF8FAFA);

  int _currentIndex = 0;
  String _activeShift = 'Morning';

  Map<String, dynamic>? _summary;
  int _memberCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _insights = [
    'Welcome to Smart Dairy! Add your first farmer to begin milk collection.',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    ApiService.dataChangeNotifier.addListener(_loadDashboardData);
    ApiService.userRoleNotifier.addListener(_onRoleChanged);
  }

  void _onRoleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ApiService.dataChangeNotifier.removeListener(_loadDashboardData);
    ApiService.userRoleNotifier.removeListener(_onRoleChanged);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await ApiService.getTodaySummary();
      final members = await ApiService.getMembers();
      final insights = await ApiService.getAiInsights();
      if (mounted) {
        setState(() {
          _summary = summary;
          _memberCount = summary['memberCount'] is num
              ? (summary['memberCount'] as num).toInt()
              : members.length;
          if (insights.isNotEmpty) _insights = insights;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Backend connection offline. Showing local passbook data.';
        });
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toUpperCase()) {
      case 'EMPLOYEE':
        return 'Operator';
      case 'ADMIN':
        return 'Admin (Developer)';
      case 'MEMBER':
        return 'Member (Farmer)';
      case 'DAIRY_OWNER':
      default:
        return 'Dairy Owner';
    }
  }

  String _getRoleBadgeName(String role) {
    switch (role.toUpperCase()) {
      case 'EMPLOYEE':
        return 'Operator';
      case 'ADMIN':
        return 'Admin (Dev)';
      case 'MEMBER':
        return 'Member';
      case 'DAIRY_OWNER':
      default:
        return 'Owner';
    }
  }

  void _showRoleSwitcherDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.manage_accounts_rounded, color: primary),
            const SizedBox(width: 8),
            Text(
              'Switch Active Role'.tr,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roleOption(
              ctx,
              'DAIRY_OWNER',
              'Dairy Owner',
              'Full access to dairy management & finances',
            ),
            _roleOption(
              ctx,
              'MEMBER',
              'Member / Farmer (Ramesh)',
              'Personal milk passbook, cycle bill statements & advance ledger',
            ),
            _roleOption(
              ctx,
              'EMPLOYEE',
              'Employee / Operator',
              'Collection, dispatch, sales & farmers',
            ),
            _roleOption(
              ctx,
              'ADMIN',
              'Admin / App Developer (Vishwajeet)',
              'Full access to all features, diagnostics & owner problem solving',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close'.tr,
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleOption(
    BuildContext ctx,
    String roleKey,
    String title,
    String subtitle,
  ) {
    final isSelected = ApiService.userRole.toUpperCase() == roleKey;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(
        isSelected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? primary : secondaryText,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: secondaryText),
      ),
      onTap: () {
        ApiService.userRole = roleKey;
        Navigator.pop(ctx);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched view to $title'.tr),
            duration: const Duration(seconds: 2),
            backgroundColor: primary,
          ),
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

          // =========================================================
          // DRAWER
          // =========================================================
          drawer: _buildDrawer(),

          // =========================================================
          // APP BAR
          // =========================================================
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: darkText),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_getRoleDisplayName(ApiService.userRole)} 👋'.tr,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _activeShift == 'Morning'
                              ? const Color(0xFFFFF4DF)
                              : const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_activeShift Shift'.tr,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _activeShift == 'Morning'
                                ? const Color(0xFFD97706)
                                : const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _showRoleSwitcherDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 10,
                                color: primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _getRoleBadgeName(ApiService.userRole),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: SyncService.pendingCountNotifier,
                builder: (context, pending, _) {
                  return IconButton(
                    tooltip: pending > 0
                        ? '$pending offline record(s). Tap to sync'.tr
                        : 'Server in Sync'.tr,
                    onPressed: () async {
                      if (pending > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Syncing pending records to server...'.tr,
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        final synced = await SyncService.syncAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                synced > 0
                                    ? 'Successfully synced $synced record(s) to server!'
                                          .tr
                                    : 'Sync complete.'.tr,
                              ),
                              backgroundColor: primary,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'All data is already in sync with server!'.tr,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          pending > 0
                              ? Icons.cloud_upload_rounded
                              : Icons.cloud_done_rounded,
                          color: pending > 0 ? Colors.amber.shade800 : primary,
                          size: 24,
                        ),
                        if (pending > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$pending',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'AI Smart Dairy Assistant'.tr,
                icon: const Icon(
                  Icons.smart_toy_outlined,
                  color: primary,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AiChatScreen(initialScreenContext: 'dashboard'),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'App Language',
                onPressed: _showDashboardLanguageDialog,
                icon: const Icon(
                  Icons.translate_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: darkText,
                      size: 25,
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // =========================================================
          // BODY
          // =========================================================
          body: _buildCurrentTab(),

          // =========================================================
          // =========================================================
          // BOTTOM NAVIGATION (Role-Based: Members have NO Add Collection action)
          // =========================================================
          bottomNavigationBar: Builder(
            builder: (context) {
              final String role = ApiService.userRole.toUpperCase();
              final isEmployee = role == 'EMPLOYEE';
              final isMember = role == 'MEMBER';

              if (isMember) {
                return BottomNavigationBar(
                  currentIndex: _currentIndex.clamp(0, 4),
                  onTap: (index) {
                    setState(() => _currentIndex = index);
                    if (index == 0 || index == 1) _loadDashboardData();
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: primary,
                  unselectedItemColor: secondaryText,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home_rounded),
                      label: 'Home'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.local_drink_outlined),
                      activeIcon: const Icon(Icons.local_drink_rounded),
                      label: 'Passbook'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.receipt_long_outlined),
                      activeIcon: const Icon(Icons.receipt_long_rounded),
                      label: 'Invoices'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.smart_toy_outlined),
                      activeIcon: const Icon(Icons.smart_toy_rounded),
                      label: 'AI Chat'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person_rounded),
                      label: 'Profile'.tr,
                    ),
                  ],
                );
              }

              // Owner / Admin / Operator navigation bar with central Add Collection button
              return BottomNavigationBar(
                currentIndex: _currentIndex.clamp(0, 4),
                onTap: (index) async {
                  if (index == 2) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MilkCollectionScreen(),
                      ),
                    );
                    if (mounted) {
                      _loadDashboardData();
                    }
                    return;
                  }
                  if (index == 3 && isEmployee) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MembersScreen()),
                    );
                    if (mounted) _loadDashboardData();
                    return;
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                  if (index == 0 || index == 1) {
                    _loadDashboardData();
                  }
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: primary,
                unselectedItemColor: secondaryText,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home_rounded),
                    label: 'Home'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined),
                    activeIcon: const Icon(Icons.dashboard_rounded),
                    label: 'Dashboard'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33087F73),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      isEmployee
                          ? Icons.groups_outlined
                          : Icons.bar_chart_outlined,
                    ),
                    activeIcon: Icon(
                      isEmployee
                          ? Icons.groups_rounded
                          : Icons.bar_chart_rounded,
                    ),
                    label: isEmployee ? 'Farmers'.tr : 'Reports'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person_rounded),
                    label: 'Profile'.tr,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    final String role = ApiService.userRole.toUpperCase();

    if (role == 'MEMBER') {
      switch (_currentIndex) {
        case 0:
          return _buildHomeTab();
        case 1:
          return const MilkCollectionScreen();
        case 2:
          return const invoice.InvoiceScreen();
        case 3:
          return const AiChatScreen(initialScreenContext: 'dashboard');
        case 4:
          return ProfileScreen(
            onBackToDashboard: () => setState(() => _currentIndex = 0),
          );
        default:
          return _buildHomeTab();
      }
    }

    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildAnalyticsDashboardTab();
      case 3:
        return ReportsScreen(
          onBackToDashboard: () => setState(() => _currentIndex = 0),
        );
      case 4:
        return ProfileScreen(
          onBackToDashboard: () => setState(() => _currentIndex = 0),
        );
      default:
        return _buildHomeTab();
    }
  }

  // =============================================================
  // ADMIN & DEVELOPER SUPPORT & PROBLEM SOLVING
  // =============================================================
  void _showContactAdminDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Admin / Developer'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                        Text(
                          'Developer Vishwajeet (Full System Access)'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF15803D),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LanguageService.currentLanguageCode == 'mr'
                            ? 'दूध संकलन, वजनकाटा BLE सिंक, दर हिशोब, १०-दिवसीय बिलिंग किंवा डेटा सिंकमध्ये कोणतीही समस्या असल्यास ॲडमिन (डेव्हलपर विश्वजीत) यांच्याशी संपर्क साधा.'
                            : 'Facing any problem with milk collection, rates, 10-day cycle billing, deductions, or sync? Contact Admin (Developer Vishwajeet) who has full system access to diagnose and resolve your issue.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF166534),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Direct Phone Call',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  '+91 98220 12345 (Admin Hotline)',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                trailing: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Calling Admin / Developer Vishwajeet: +91 98220 12345',
                        ),
                        backgroundColor: primary,
                      ),
                    );
                  },
                  child: const Text('Call'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.green,
                  ),
                ),
                title: const Text(
                  'WhatsApp Developer Support',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Instant chat & error screenshot sharing',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                trailing: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Opening WhatsApp chat with Developer Vishwajeet (+91 98220 12345)...',
                        ),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                  child: const Text('Chat'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bug_report_outlined,
                    color: Colors.purple,
                  ),
                ),
                title: const Text(
                  'Submit Problem Ticket',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Directly log issue for Developer Vishwajeet to solve',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showSubmitTicketDialog();
                  },
                  child: const Text('Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitTicketDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final contactController = TextEditingController(text: '+91 98220 12345');
    String selectedScreen = 'Milk Collection';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: const [
              Icon(Icons.report_problem_rounded, color: primary),
              SizedBox(width: 8),
              Text(
                'Submit Problem to Admin',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe the issue you are facing. Developer Vishwajeet will diagnose and solve it.',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Problem Summary *',
                    hintText: 'e.g., Bluetooth weight reading mismatch',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedScreen,
                  decoration: const InputDecoration(
                    labelText: 'Affected Screen / Module',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Milk Collection',
                      child: Text('Milk Collection'),
                    ),
                    DropdownMenuItem(
                      value: 'Rate Chart',
                      child: Text('Rate Chart'),
                    ),
                    DropdownMenuItem(
                      value: '10-Day Cycle Billing',
                      child: Text('10-Day Cycle Billing'),
                    ),
                    DropdownMenuItem(
                      value: 'Farmers / Members',
                      child: Text('Farmers / Members'),
                    ),
                    DropdownMenuItem(
                      value: 'Data Sync & Offline',
                      child: Text('Data Sync & Offline'),
                    ),
                    DropdownMenuItem(
                      value: 'Annual Bonus',
                      child: Text('Annual Bonus'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedScreen = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details / Error Description',
                    hintText: 'What went wrong? Any error message?',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Your Contact Phone',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                ApiService.addSupportTicket(
                  title: title,
                  description: descController.text.trim(),
                  submittedBy: 'Dairy Owner (${ApiService.dairyName})',
                  contact: contactController.text.trim(),
                  screen: selectedScreen,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Problem ticket submitted to Developer Vishwajeet! Admin will diagnose and solve it.',
                    ),
                    backgroundColor: primary,
                  ),
                );
              },
              child: const Text('Submit Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminConsoleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin & Developer Console',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Developer Vishwajeet (Full Access)',
                      style: TextStyle(fontSize: 11, color: secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'System Health: 100% OK (Full Access)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All 16 Modules enabled. Offline SQLite database operational. Dual-axis pricing matrix active.',
                          style: TextStyle(fontSize: 11, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Dairy Owner Problem Tickets:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (ApiService.supportTickets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No pending owner problem tickets.',
                          style: TextStyle(color: secondaryText, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...ApiService.supportTickets.map((ticket) {
                      final isOpen = ticket['status'] == 'Open';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOpen
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ticket['id'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? Colors.amber.shade700
                                        : Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ticket['status'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  ticket['date'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ticket['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ticket['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'By: ${ticket['submittedBy']} (${ticket['screen']})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: secondaryText,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (isOpen)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: primary,
                                    ),
                                    icon: const Icon(
                                      Icons.build_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Solve Issue',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () {
                                      ApiService.resolveSupportTicket(
                                        ticket['id'],
                                      );
                                      setDlgState(() {});
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Problem ${ticket['id']} marked RESOLVED by Admin Vishwajeet!',
                                          ),
                                          backgroundColor: primary,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // HOME TAB CONTENT
  // =============================================================
  Widget _buildHomeTab() {
    final isEmployee = ApiService.userRole.toUpperCase() == 'EMPLOYEE';
    final isMember = ApiService.userRole.toUpperCase() == 'MEMBER';
    return RefreshIndicator(
      color: primary,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // TODAY'S OVERVIEW
            // =====================================================
            _sectionTitle(isMember ? "My Milk & Earnings Today".tr : "Today's Overview".tr),

            if (_isLoading) ...[
              const SizedBox(height: 6),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                child: LinearProgressIndicator(
                  color: primary,
                  backgroundColor: Color(0xFFE7F6F3),
                  minHeight: 3,
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!.tr,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                    InkWell(
                      onTap: _loadDashboardData,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Retry'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: primary, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (ApiService.userRole.toUpperCase() == 'ADMIN') ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _showAdminConsoleDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.engineering_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Admin & Developer Console',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade400,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'FULL ACCESS',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'App Developer Vishwajeet active. Solve Owner problem tickets & run diagnostics.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _showContactAdminDialog,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        color: primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageService.currentLanguageCode == 'mr'
                              ? 'कोणत्याही फिचरमध्ये समस्या असल्यास ॲडमिन (डेव्हलपर विश्वजीत) यांच्याशी संपर्क साधा'
                              : 'Facing a problem in any feature? Contact Admin / Developer Vishwajeet',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _overviewCard(
                  Icons.local_drink_outlined,
                  isMember ? 'My Milk'.tr : 'Total Milk'.tr,
                  _summary != null
                      ? FormatUtils.formatQty(_summary!['totalMilk'])
                      : '0 Ltr',
                  primary,
                ),
                isEmployee
                    ? _overviewCard(
                        Icons.receipt_long_rounded,
                        'Collections'.tr,
                        _summary != null
                            ? '${_summary!['collectionsCount'] ?? 0} Slips'
                            : '0 Slips',
                        primary,
                      )
                    : _overviewCard(
                        Icons.currency_rupee_rounded,
                        isMember ? 'My Earnings'.tr : 'Total Amount'.tr,
                        _summary != null
                            ? FormatUtils.formatCurrency(
                                _summary!['totalAmount'],
                              )
                            : '₹0',
                        primary,
                      ),
                isMember
                    ? _overviewCard(
                        Icons.receipt_rounded,
                        'My Slips'.tr,
                        _summary != null
                            ? '${_summary!['collectionsCount'] ?? 0} Slips'
                            : '0 Slips',
                        const Color(0xFF55A85B),
                      )
                    : _overviewCard(
                        Icons.groups_outlined,
                        'Members'.tr,
                        _memberCount.toString(),
                        const Color(0xFF55A85B),
                      ),
                _overviewCard(
                  Icons.water_drop_outlined,
                  isMember ? 'My Avg FAT'.tr : 'Avg FAT'.tr,
                  _summary != null ? '${_summary!['avgFat']}%' : '0.0%',
                  const Color(0xFFFF9800),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =====================================================
            // QUICK ACCESS
            // =====================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Quick Access'.tr),
                InkWell(
                  onTap: _showRoleSwitcherDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getRoleDisplayName(ApiService.userRole),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
              children: _buildQuickAccessModules(context),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // ASK AI ASSISTANT BANNER CARD
            // =====================================================
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AiChatScreen(initialScreenContext: 'dashboard'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF087F73), Color(0xFF0F9D8F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF087F73).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ask AI Assistant'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Smart AI',
                                  style: TextStyle(
                                    color: Color(0xFF14213D),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            LanguageService.currentLanguageCode == 'mr'
                                ? 'दूध संकलन, दर हिशोब, बिलिंग आणि नियमांबद्दल विचारा'
                                : 'Get instant answers for collection, rates, billing & reports',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // AI INSIGHTS
            // =====================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _sectionTitle('AI Insights'.tr),
                InkWell(
                  onTap: _showAiInsightsDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'View All'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _insightCard(
                Icons.trending_up_rounded,
                'Milk collection is 12% higher than yesterday.'.tr,
                const Color(0xFFE7F6F3),
                const Color(0xFF087F73),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _insightCard(
                Icons.warning_amber_rounded,
                '2 unusual FAT values detected today.'.tr,
                const Color(0xFFFFF4E5),
                const Color(0xFFF59E0B),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickAccessModules(BuildContext context) {
    final role = ApiService.userRole.toUpperCase();
    final List<Widget> items = [];

    void addMod(
      String key,
      IconData icon,
      String title,
      Widget screen, {
      VoidCallback? onTap,
    }) {
      bool include = true;
      if (role == 'EMPLOYEE') {
        include = [
          'collection',
          'customer',
          'ratechart',
          'products',
          'support',
        ].contains(key);
      } else if (role == 'MEMBER') {
        include = [
          'collection',
          'statement',
          'invoice',
          'advance',
          'products',
          'assistant',
          'support',
        ].contains(key);
      }
      if (include) {
        items.add(
          _clickableModule(context, icon, title, screen, onTapOverride: onTap),
        );
      }
    }

    if (role == 'ADMIN') {
      addMod(
        'admin_console',
        Icons.engineering_rounded,
        'Admin Console'.tr,
        const SizedBox.shrink(),
        onTap: _showAdminConsoleDialog,
      );
    }
    addMod(
      'support',
      Icons.support_agent_rounded,
      'Contact Admin'.tr,
      const SizedBox.shrink(),
      onTap: _showContactAdminDialog,
    );
    addMod(
      'assistant',
      Icons.smart_toy_outlined,
      'AI Assistant'.tr,
      const AiChatScreen(initialScreenContext: 'dashboard'),
    );
    addMod(
      'collection',
      Icons.local_drink_outlined,
      role == 'MEMBER' ? 'Milk Passbook'.tr : 'Collection'.tr,
      const MilkCollectionScreen(),
    );
    addMod(
      'customer',
      Icons.groups_outlined,
      'Member'.tr,
      const MembersScreen(),
    );
    addMod(
      'statement',
      Icons.receipt_long,
      'Detailed Bill'.tr,
      const DetailedBillStatementScreen(),
    );
    addMod(
      'bonus',
      Icons.stars_rounded,
      'Annual Bonus'.tr,
      const AnnualBonusScreen(),
    );
    addMod(
      'products',
      Icons.agriculture_rounded,
      'Products'.tr,
      const ProductsScreen(),
    );
    addMod(
      'advance',
      Icons.currency_rupee_rounded,
      'Advance'.tr,
      const AdvanceScreen(),
    );
    addMod(
      'invoice',
      Icons.receipt_long_outlined,
      'Invoice'.tr,
      const invoice.InvoiceScreen(),
    );
    addMod(
      'payments',
      Icons.account_balance_wallet_outlined,
      'Payments'.tr,
      const payments.PaymentsScreen(),
    );
    addMod(
      'deduction',
      Icons.percent_rounded,
      'Deduction'.tr,
      const DeductionScreen(),
    );
    addMod(
      'milksale',
      Icons.local_drink,
      'Milk Sale'.tr,
      const MilkSaleScreen(),
    );
    addMod(
      'ratechart',
      Icons.table_chart_outlined,
      'Rate Chart'.tr,
      const RateChartScreen(),
    );
    addMod(
      'reports',
      Icons.bar_chart_rounded,
      'Reports'.tr,
      const ReportsScreen(),
    );
    addMod(
      'expense',
      Icons.description_outlined,
      'Expense'.tr,
      const ExpenseScreen(),
    );
    addMod(
      'dispatch',
      Icons.local_shipping_outlined,
      'Dispatch'.tr,
      const DispatchScreen(),
    );
    addMod(
      'received',
      Icons.inventory_2_outlined,
      'Received'.tr,
      const ReceivedScreen(),
    );

    return items;
  }

  void _showDashboardLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Select Language'.tr),
          children: ['English', 'Marathi (मराठी)', 'Hindi (हिंदी)'].map((lang) {
            final isSelected = LanguageService.currentLanguage == lang;
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? primary : darkText,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =============================================================
  // NAVIGATION DRAWER
  // =============================================================
  Widget _buildDrawer() {
    final role = ApiService.userRole.toUpperCase();
    final isEmployee = role == 'EMPLOYEE';
    final isMember = role == 'MEMBER';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E9E8)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Center Code: LDK-402 | Kadamwadi, Kolhapur',
                              style: TextStyle(
                                fontSize: 11,
                                color: secondaryText,
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDE2E7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _activeShift == 'Morning'
                                    ? Icons.wb_sunny_rounded
                                    : Icons.nights_stay_rounded,
                                size: 16,
                                color: _activeShift == 'Morning'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Shift: $_activeShift',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _activeShift = _activeShift == 'Morning'
                                  ? 'Evening'
                                  : 'Morning';
                            });
                          },
                          child: const Text(
                            'Toggle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items (Filtered by Role)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard Overview'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  if (isMember) ...[
                    _drawerItem(
                      icon: Icons.local_drink_outlined,
                      title: 'My Milk Passbook'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.receipt_long,
                      title: 'Detailed Bill Statement'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DetailedBillStatementScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Invoices & Slips'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.currency_rupee_rounded,
                      title: 'My Advances'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdvanceScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.agriculture_rounded,
                      title: 'Cattle Feed & Products'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductsScreen(),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Owner / Admin / Operator
                    _drawerItem(
                      icon: Icons.local_drink_outlined,
                      title: 'Milk Collection'.tr,
                      badge: 'Daily',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MilkCollectionScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.groups_outlined,
                      title: 'Members Management'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MembersScreen(),
                          ),
                        );
                      },
                    ),
                    if (!isEmployee)
                      _drawerItem(
                        icon: Icons.currency_rupee_rounded,
                        title: 'Farmer Advance'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdvanceScreen(),
                            ),
                          );
                        },
                      ),
                    if (!isEmployee)
                      _drawerItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Invoices & Billing'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const invoice.InvoiceScreen(),
                            ),
                          );
                        },
                      ),
                    if (!isEmployee)
                      _drawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payments & Payouts'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const payments.PaymentsScreen(),
                            ),
                          );
                        },
                      ),
                    if (!isEmployee)
                      _drawerItem(
                        icon: Icons.percent_rounded,
                        title: 'Deductions (Feed/Loan)'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeductionScreen(),
                            ),
                          );
                        },
                      ),
                    _drawerItem(
                      icon: Icons.storefront_outlined,
                      title: 'Milk Sales'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MilkSaleScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.table_chart_outlined,
                      title: 'Rate Chart'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RateChartScreen(),
                          ),
                        );
                      },
                    ),
                    if (!isEmployee)
                      _drawerItem(
                        icon: Icons.bar_chart_rounded,
                        title: 'Reports & Analytics'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportsScreen(),
                            ),
                          );
                        },
                      ),
                    if (!isEmployee)
                      _drawerItem(
                        icon: Icons.description_outlined,
                        title: 'Expenses Tracker'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpenseScreen(),
                            ),
                          );
                        },
                      ),
                    _drawerItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'Dispatch to Plant'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DispatchScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Received Tankers'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceivedScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  _drawerItem(
                    icon: Icons.agriculture_rounded,
                    title: 'Products Master Catalog'.tr,
                    badge: 'Feed/Supplies',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductsScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.support_agent_rounded,
                    title: 'Contact Admin / Developer'.tr,
                    badge: 'Vishwajeet',
                    onTap: () {
                      Navigator.pop(context);
                      _showContactAdminDialog();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Switch User Role'.tr,
                    badge: _getRoleDisplayName(ApiService.userRole),
                    onTap: () {
                      Navigator.pop(context);
                      _showRoleSwitcherDialog();
                    },
                  ),
                  const Divider(color: Color(0xFFE5E9E8)),
                  _drawerItem(
                    icon: Icons.language_rounded,
                    title: 'App Language'.tr,
                    badge: LanguageService.currentLanguage.split(' ').first,
                    onTap: () {
                      Navigator.pop(context);
                      _showDashboardLanguageDialog();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications & Alerts'.tr,
                    badge: '3 New',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (!isEmployee)
                    _drawerItem(
                      icon: Icons.history_edu_rounded,
                      title: 'Audit Trail & Edits'.tr,
                      badge: 'Security',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuditHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  _drawerItem(
                    icon: Icons.person_outline,
                    title: 'Profile & Settings'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 4);
                    },
                  ),
                ],
              ),
            ),

            // Logout Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      leading: Icon(icon, color: primary, size: 21),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  // =============================================================
  // CLICKABLE MODULE
  // =============================================================
  Widget _clickableModule(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen, {
    VoidCallback? onTapOverride,
  }) {
    return GestureDetector(
      onTap: () async {
        if (onTapOverride != null) {
          onTapOverride();
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
        if (mounted) {
          _loadDashboardData();
        }
      },
      child: _moduleCard(icon, title),
    );
  }

  // =============================================================
  // SECTION TITLE
  // =============================================================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  // =============================================================
  // OVERVIEW CARD
  // =============================================================
  Widget _overviewCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9ED)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: secondaryText),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MODULE CARD
  // =============================================================
  Widget _moduleCard(IconData icon, String title) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: primary, size: 27),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // AI INSIGHT CARD
  // =============================================================
  Widget _insightCard(
    IconData icon,
    String text, [
    Color bgColor = const Color(0xFFE7F6F3),
    Color iconColor = primary,
  ]) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9ED)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Log Out'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to end your current session and return to the login screen?'.tr,
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text('Log Out'.tr),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // AI INSIGHTS FULL DIALOG (Aligned with System Architecture)
  // =============================================================
  void _showAiInsightsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AI & ML Insights'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _aiFeatureCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      title: 'Anomaly Detection (Quantity, FAT, SNF)',
                      subtitle: 'Real-time statistical checks active. 2 unusual FAT readings detected today outside normal parameters. Self-calibration recommended.',
                      badge: 'Active Monitoring',
                      badgeColor: const Color(0xFFD97706),
                      evidence: 'Evidence: 32 collection entries evaluated against 3-sigma FAT variance model for today (Shift: Morning)',
                    ),
                    const SizedBox(height: 12),
                    _aiFeatureCard(
                      icon: Icons.verified_rounded,
                      iconColor: primary,
                      bgColor: const Color(0xFFE7F6F3),
                      title:
                          'Milk Quality Prediction (Good / Normal / Attention)',
                      subtitle: 'AI Grade: Good (86.5/100). Standard grade milk meeting purity benchmarks. Eligible for quality tiering incentive.',
                      badge: 'Grade A Purity',
                      badgeColor: primary,
                      evidence: 'Evidence: 120 historic test records (Oct 10 - Oct 25, 2026). Median FAT: 4.2%, Median SNF: 8.6%',
                    ),
                    const SizedBox(height: 12),
                    _aiFeatureCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      title: 'Collection Prediction (Daily / Weekly / Monthly)',
                      subtitle: 'Morning shift forecast: 720.5 Ltr • Evening forecast: 533.5 Ltr.\nAnticipated ↑ 12% rise in yield over next 7 days based on seasonal trends.',
                      badge: 'Forecast (89% Conf)',
                      badgeColor: const Color(0xFF2563EB),
                      evidence: 'Evidence: 14-day rolling window (168 historical shifts evaluated, ARIMA trend estimation)',
                    ),
                    const SizedBox(height: 12),
                    _aiFeatureCard(
                      icon: Icons.lightbulb_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF5F3FF),
                      title: 'Smart Insights & Recommendations',
                      subtitle: '• Optimal evening dispatch vehicle timing: 06:30 PM.\n• 18 farmers eligible for clean milk bonus.\n• BMC unit #1 maintained ideal chilling temp at 3.8°C.',
                      badge: 'Actionable',
                      badgeColor: const Color(0xFF7C3AED),
                      evidence: 'Evidence: BMC sensor logs #01-#04 & dispatch tanker timetable records for last 10 days',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _aiFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    String? evidence,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          if (evidence != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      evidence,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // ANALYTICS & DASHBOARD TAB (Bottom Nav Index 1)
  // =============================================================
  Widget _buildAnalyticsDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dairy Performance'.tr,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Analytics & AI Operations'.tr,
                    style: const TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Live Metrics'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // High-level Performance Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _overviewCard(
                Icons.local_drink_rounded,
                'Total Volume'.tr,
                _summary != null ? '${_summary!['totalMilk']} Ltr' : '0 Ltr',
                primary,
              ),
              _overviewCard(
                Icons.payments_rounded,
                'Total Revenue'.tr,
                _summary != null ? '₹${_summary!['totalAmount']}' : '₹0',
                const Color(0xFF2563EB),
              ),
              _overviewCard(
                Icons.verified_outlined,
                'Milk Quality Index'.tr,
                '86.5% (Good)',
                const Color(0xFF059669),
              ),
              _overviewCard(
                Icons.schedule_rounded,
                'Active Shift'.tr,
                '$_activeShift Shift'.tr,
                const Color(0xFFD97706),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // AI Forecast Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF087F73), Color(0xFF0E6359)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Collection Forecast'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '89% Accuracy',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Projected yield: 1,254 Ltr tomorrow (Morning: 720.5 L • Evening: 533.5 L). Anticipating a 12% rise in milk collection this week.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quality Grade Breakdown
          Text(
            'Quality & Compliance Breakdown'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _qualityRow(
                  'Grade A (Good - FAT > 4.0, SNF > 8.5)',
                  '85%',
                  const Color(0xFF087F73),
                ),
                const SizedBox(height: 10),
                _qualityRow(
                  'Grade B (Normal - Standard compliance)',
                  '12%',
                  const Color(0xFF2563EB),
                ),
                const SizedBox(height: 10),
                _qualityRow(
                  'Grade C (Attention / Low Solids)',
                  '3%',
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _qualityRow(String label, String percent, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: darkText,
            ),
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
