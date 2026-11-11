import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class AuditHistoryScreen extends StatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  State<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends State<AuditHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'ALL';
  bool _isLoading = false;
  List<Map<String, dynamic>> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ApiService.getAuditLogs();
      if (mounted) {
        setState(() {
          _auditLogs = logs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    return _auditLogs.where((log) {
      final action = (log['action'] ?? '').toString();
      final type = (log['entityType'] ?? '').toString();
      final details = (log['details'] ?? '').toString().toLowerCase();
      final user = (log['performedBy'] ?? '').toString().toLowerCase();

      final matchesFilter = switch (_selectedFilter) {
        'COLLECTION' => action.contains('COLLECTION') || type == 'COLLECTION',
        'PAYMENT' => action.contains('PAYMENT') || type == 'PAYMENT',
        'ADVANCE' => action.contains('ADVANCE') || type == 'ADVANCE',
        'SECURITY' => action.contains('LOGIN') || action.contains('AUTH'),
        _ => true,
      };

      final matchesQuery = query.isEmpty || details.contains(query) || user.contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Color _getActionColor(String action) {
    if (action.contains('COLLECTION')) return const Color(0xFF087F73);
    if (action.contains('PAYMENT')) return const Color(0xFF7C3AED);
    if (action.contains('ADVANCE')) return const Color(0xFFD97706);
    if (action.contains('LOGIN')) return const Color(0xFF2563EB);
    return const Color(0xFF4B5563);
  }

  IconData _getActionIcon(String action) {
    if (action.contains('COLLECTION')) return Icons.water_drop_outlined;
    if (action.contains('PAYMENT')) return Icons.payments_outlined;
    if (action.contains('ADVANCE')) return Icons.account_balance_wallet_outlined;
    if (action.contains('LOGIN')) return Icons.security_rounded;
    return Icons.history_rounded;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF087F73);
    final filtered = _filteredLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Audit History & Edits'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF14213D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAuditLogs,
            tooltip: 'Refresh audit log',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search audit records by member or details...'.tr,
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: primary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All'.tr, 'ALL'),
                      const SizedBox(width: 8),
                      _filterChip('Collections'.tr, 'COLLECTION'),
                      const SizedBox(width: 8),
                      _filterChip('Payments'.tr, 'PAYMENT'),
                      const SizedBox(width: 8),
                      _filterChip('Advances'.tr, 'ADVANCE'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No audit records found'.tr,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'All operational edits, collections, disbursements and changes are logged securely.'.tr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _fetchAuditLogs,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final log = filtered[index];
                            final action = (log['action'] ?? 'ACTION').toString();
                            final color = _getActionColor(action);
                            final icon = _getActionIcon(action);
                            final timestamp = (log['timestamp'] ?? '').toString();

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(icon, color: color, size: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            action.replaceAll('_', ' '),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (log['role'] ?? 'OWNER').toString().replaceAll('ROLE_', ''),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    log['details'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            log['performedBy'] ?? 'Dairy Owner',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        timestamp.length > 16 ? timestamp.substring(0, 16).replaceAll('T', ' ') : timestamp,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: const Color(0xFF087F73),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }
}
