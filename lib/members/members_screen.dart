import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../payments/add_payment_screen.dart';
import '../invoice/detailed_bill_statement_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController searchController =
  TextEditingController();

  bool _isLoading = false;

  final List<Map<String, dynamic>> members = [];
  String _selectedCycle = '10_days';
  final Map<String, Map<String, Map<String, double>>> _memberCycleData = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMembers();
      if (mounted) {
        setState(() {
          members.clear();
          int idx = 1;
          for (final item in data) {
            final code = (item['memberCode'] ?? (idx++).toString()).toString();
            members.add({
              'id': code,
              'name': item['name'] ?? 'Member',
              'phone': item['phone'] ?? '',
              'animal': item['animalType'] ?? 'Cow',
              'milk': '${item['totalMilkSupplied'] ?? 0.0} L',
              'fat': '${item['avgFat'] ?? 4.2}',
              'snf': item['snf']?.toString() ?? '8.5',
              'status': (item['active'] ?? true) ? 'Active' : 'Inactive',
            });
          }
        });

        // Load multi-cycle totals (10, 15, Monthly, Yearly) for each member
        for (final m in members) {
          final code = m['id'].toString();
          final cycleData = await ApiService.getMemberCycleTotals(code);
          if (mounted) {
            setState(() {
              _memberCycleData[code] = cycleData;
            });
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _getCycleTitle(String key) {
    switch (key) {
      case '10_days':
        return '10 Days';
      case '15_days':
        return '15 Days';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Cycle';
    }
  }

  int _getTotalCyclePayable() {
    double total = 0.0;
    for (final m in members) {
      final code = m['id'].toString();
      final amt = _memberCycleData[code]?[_selectedCycle]?['amount'] ?? 0.0;
      total += amt;
    }
    return total.round();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredMembers {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return members;
    }

    return members.where((member) {
      final name =
      member['name'].toString().toLowerCase();

      final phone =
      member['phone'].toString().toLowerCase();

      return name.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF43A99F),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members'.tr,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur'.tr,
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              size: 28,
            ),
            onPressed: () {
              _showSearchDialog();
            },
          ),

          IconButton(
            icon: const Icon(
              Icons.add,
              size: 32,
            ),
            onPressed: () {
              _showAddMemberDialog();
            },
          ),

          IconButton(
            icon: const Icon(
              Icons.more_vert,
            ),
            onPressed: () {},
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF087F73),
              backgroundColor: Color(0xFFE7F6F3),
            ),

          _buildSummary(),

          _buildCycleSelector(),

          _buildSearchBar(),

          Expanded(
            child: filteredMembers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member =
                filteredMembers[index];

                return _memberCard(member);
              },
            ),
          ),
        ],
      ),

      // =====================================================
      // FLOATING BUTTON
      // =====================================================

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF087F73),
        foregroundColor: Colors.white,

        onPressed: () {
          _showAddMemberDialog();
        },

        child: const Icon(
          Icons.person_add_alt_1,
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummary() {
    return Container(
      color: Colors.white,

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),

      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              Icons.groups_outlined,
              'Total Members'.tr,
              members.length.toString(),
            ),
          ),

          Expanded(
            child: _summaryItem(
              Icons.check_circle_outline,
              'Active'.tr,
              members
                  .where(
                    (member) =>
                member['status'] == 'Active',
              )
                  .length
                  .toString(),
            ),
          ),

          Expanded(
            child: _summaryItem(
              Icons.currency_rupee_rounded,
              '${_getCycleTitle(_selectedCycle)} Due'.tr,
              '₹${_getTotalCyclePayable()}',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CYCLE SELECTOR
  // =========================================================

  Widget _buildCycleSelector() {
    final cycles = [
      {'key': '10_days', 'label': '10 Days'.tr},
      {'key': '15_days', 'label': '15 Days'.tr},
      {'key': 'monthly', 'label': 'Monthly'.tr},
      {'key': 'yearly', 'label': 'Yearly'.tr},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: cycles.map((c) {
            final isSelected = _selectedCycle == c['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCycle = c['key']!;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF087F73) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF087F73).withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _summaryItem(
      IconData icon,
      String title,
      String value,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF087F73),
          size: 24,
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14213D),
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF7A869A),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SEARCH BAR
  // =========================================================

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFFF8FAFA),

      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),

      child: TextField(
        controller: searchController,

        onChanged: (_) {
          setState(() {});
        },

        decoration: InputDecoration(
          hintText: 'Search member by name or phone',

          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF777777),
          ),

          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(
              Icons.clear,
            ),
            onPressed: () {
              searchController.clear();

              setState(() {});
            },
          )
              : null,

          filled: true,
          fillColor: Colors.white,

          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 12,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(
              color: Color(0xFFE1E5E9),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(
              color: Color(0xFFE1E5E9),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(
              color: Color(0xFF43A99F),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MEMBER CARD
  // =========================================================

  Widget _memberCard(
      Map<String, dynamic> member,
      ) {
    final bool isBuffalo =
        member['animal'] == 'Buffalo';

    return InkWell(
      onTap: () => _showMemberDetailsSheet(member),
      child: Container(
        color: Colors.white,

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        margin: const EdgeInsets.only(
          bottom: 1,
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
          // MEMBER NUMBER

          SizedBox(
            width: 28,

            child: Text(
              member['id'].toString(),

              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF777777),
              ),
            ),
          ),

          // ANIMAL ICON

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: isBuffalo
                  ? const Color(0xFFFFF2E2)
                  : const Color(0xFFE7F6F3),

              borderRadius:
              BorderRadius.circular(12),
            ),

            alignment: Alignment.center,

            child: Text(
              isBuffalo ? '🐃' : '🐄',

              style: const TextStyle(
                fontSize: 23,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // MEMBER INFORMATION

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  member['name'].toString(),

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF14213D),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  member['phone'].toString(),

                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Text(
                      isBuffalo
                          ? 'Buffalo'
                          : 'Cow',

                      style: TextStyle(
                        fontSize: 11,
                        color: isBuffalo
                            ? const Color(
                          0xFFB66A16,
                        )
                            : const Color(
                          0xFF087F73,
                        ),
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'FAT ${member['fat']}',

                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF666666),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'SNF ${member['snf']}',

                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_getCycleTitle(_selectedCycle)}: ${((_memberCycleData[member['id'].toString()]?[_selectedCycle]?['litres'] ?? 0.0) as double).toStringAsFixed(1)} L • ₹${((_memberCycleData[member['id'].toString()]?[_selectedCycle]?['amount'] ?? 0.0) as double).round()}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF087F73),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // MILK & CYCLE PAYABLE
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${((_memberCycleData[member['id'].toString()]?[_selectedCycle]?['litres'] ?? 0.0) as double).toStringAsFixed(1)} L',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF087F73),
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6F3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${((_memberCycleData[member['id'].toString()]?[_selectedCycle]?['amount'] ?? 0.0) as double).round()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF087F73),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,

                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Color(0xFF777777),
                ),

                onSelected: (value) {
                  if (value == 'statement') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailedBillStatementScreen(
                          initialMemberCode: member['id'].toString(),
                        ),
                      ),
                    );
                  }

                  if (value == 'edit') {
                    _showEditMemberDialog(
                      member,
                    );
                  }

                  if (value == 'login_creds') {
                    _showCreateMemberLoginDialog(member);
                  }

                  if (value == 'delete') {
                    _deleteMember(member);
                  }
                },

                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'statement',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF087F73)),
                          SizedBox(width: 8),
                          Text('Cycle Statement (बिल)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'login_creds',
                      child: Row(
                        children: [
                          Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF087F73)),
                          SizedBox(width: 8),
                          Text('Mobile Login (लॉगिन)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    final bool isSearch = searchController.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF087F73).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 40,
                color: Color(0xFF087F73),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No members found'.tr : 'No Farmers Registered Yet'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try another name or phone number.'.tr
                  : 'Start by registering your first dairy member to begin milk collection.'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A869A),
              ),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showAddMemberDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087F73),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Add First Farmer'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH DIALOG
  // =========================================================

  void _showSearchDialog() {
    showDialog(
      context: context,

      builder: (context) {
        final controller =
        TextEditingController();

        return AlertDialog(
          title: const Text(
            'Search Member',
          ),

          content: TextField(
            controller: controller,

            autofocus: true,

            decoration:
            const InputDecoration(
              hintText: 'Enter name or phone',
              prefixIcon: Icon(Icons.search),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              onPressed: () {
                searchController.text =
                    controller.text;

                setState(() {});

                Navigator.pop(context);
              },
              child: const Text('SEARCH'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // ADD MEMBER
  // =========================================================

  void _showAddMemberDialog() {
    final nameController =
    TextEditingController();

    final phoneController =
    TextEditingController();

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Member',
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: nameController,
                inputFormatters: ValidationUtils.lettersOnlyFormatter,

                decoration:
                const InputDecoration(
                  labelText: 'Member Name',
                  prefixIcon:
                  Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                inputFormatters: ValidationUtils.phoneFormatter,

                keyboardType:
                TextInputType.phone,

                decoration:
                const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon:
                  Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final nameErr = ValidationUtils.validateName(name);
                if (nameErr != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(nameErr), backgroundColor: Colors.red),
                  );
                  return;
                }

                Navigator.pop(context);

                final memberData = {
                  'name': name,
                  'phone': phone,
                  'animalType': 'Cow',
                  'avgFat': 4.2,
                };

                final saved = await ApiService.addMember(memberData);
                final code = (saved != null && saved['memberCode'] != null)
                    ? saved['memberCode'].toString()
                    : '';
                if (mounted) {
                  _loadMembers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(code.isNotEmpty
                          ? 'Member "$name" added successfully! Code: #$code'.tr
                          : 'Member "$name" added successfully!'.tr),
                      backgroundColor: const Color(0xFF087F73),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // EDIT MEMBER
  // =========================================================

  void _showEditMemberDialog(
      Map<String, dynamic> member,
      ) {
    final nameController =
    TextEditingController(
      text: member['name'].toString(),
    );

    final phoneController =
    TextEditingController(
      text: member['phone'].toString(),
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Member',
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: nameController,
                inputFormatters: ValidationUtils.lettersOnlyFormatter,

                decoration:
                const InputDecoration(
                  labelText: 'Member Name',
                  prefixIcon:
                  Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                inputFormatters: ValidationUtils.phoneFormatter,

                keyboardType:
                TextInputType.phone,

                decoration:
                const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon:
                  Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final nameErr = ValidationUtils.validateName(name);
                if (nameErr != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(nameErr), backgroundColor: Colors.red),
                  );
                  return;
                }
                final code = member['id'].toString();

                Navigator.pop(context);

                await ApiService.updateMember(code, {
                  'name': name,
                  'phone': phone,
                });

                if (mounted) {
                  _loadMembers();
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // DELETE MEMBER
  // =========================================================

  void _deleteMember(
      Map<String, dynamic> member,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Member?',
          ),

          content: Text(
            'Are you sure you want to delete '
                '${member['name']}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),

              onPressed: () async {
                final code = member['id'].toString();
                Navigator.pop(context);

                await ApiService.deleteMember(code);
                if (mounted) {
                  _loadMembers();
                }
              },

              child: const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MEMBER DETAILS / PASSBOOK SHEET
  // =========================================================

  void _showMemberDetailsSheet(Map<String, dynamic> member) {
    final isBuffalo = member['animal'] == 'Buffalo';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isBuffalo
                            ? const Color(0xFFFFF2E2)
                            : const Color(0xFFE7F6F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isBuffalo ? '🐃' : '🐄',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF14213D),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7EC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  member['status'].toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3C9145),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Member #${member['id']} • ${member['phone']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // Financial Summary
                Row(
                  children: [
                    Expanded(
                      child: _passbookStat(
                        'Total Milk',
                        member['milk'].toString(),
                        const Color(0xFF087F73),
                        Icons.local_drink_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _passbookStat(
                        'Avg FAT',
                        '${member['fat']}%',
                        const Color(0xFFFF9800),
                        Icons.water_drop_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _passbookStat(
                        'Advance Bal.',
                        '₹1,500',
                        Colors.redAccent,
                        Icons.currency_rupee_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Payment Billing Cycles (10, 15, Monthly, Yearly)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Billing Cycles'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    Text(
                      'Milk & Amount Due'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF087F73),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final memberCode = member['id'].toString();
                    final cycleData = _memberCycleData[memberCode] ?? {
                      '10_days': {'litres': 0.0, 'amount': 0.0},
                      '15_days': {'litres': 0.0, 'amount': 0.0},
                      'monthly': {'litres': 0.0, 'amount': 0.0},
                      'yearly': {'litres': 0.0, 'amount': 0.0},
                    };
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _cycleRow('10 Days', cycleData['10_days']?['litres'] ?? 0.0, cycleData['10_days']?['amount'] ?? 0.0),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _cycleRow('15 Days', cycleData['15_days']?['litres'] ?? 0.0, cycleData['15_days']?['amount'] ?? 0.0),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _cycleRow('Monthly', cycleData['monthly']?['litres'] ?? 0.0, cycleData['monthly']?['amount'] ?? 0.0),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _cycleRow('Yearly', cycleData['yearly']?['litres'] ?? 0.0, cycleData['yearly']?['amount'] ?? 0.0),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Pay Farmer CTA
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPaymentScreen(
                            onSave: (paymentData) {
                              ApiService.createPayment(paymentData);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.currency_rupee_rounded, size: 18),
                    label: Text(
                      'Give Farmer Payment'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF087F73),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Banking & Payout Details
                const Text(
                  'Bank & Payout Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF14213D),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E9E8)),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Bank Name', 'State Bank of India'),
                      const SizedBox(height: 6),
                      _infoRow('Account Number', '•••• •••• 4821'),
                      const SizedBox(height: 6),
                      _infoRow('IFSC Code', 'SBIN0001842'),
                      const SizedBox(height: 6),
                      _infoRow('UPI ID', '${member['name'].toString().toLowerCase().replaceAll(' ', '')}@upi'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Member Mobile App Login
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF087F73),
                      side: const BorderSide(color: Color(0xFF087F73)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateMemberLoginDialog(member);
                    },
                    icon: const Icon(Icons.phone_android_rounded, size: 18),
                    label: const Text('Member Mobile App Login / Credentials'),
                  ),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF087F73),
                          side: const BorderSide(color: Color(0xFF087F73)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling ${member['name']} at ${member['phone']}...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: const Text('Call Member'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF087F73),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditMemberDialog(member);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Member'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _passbookStat(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7A869A)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF14213D),
          ),
        ),
      ],
    );
  }

  Widget _cycleRow(String title, double litres, double amount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F6F3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title.tr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF087F73),
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${litres.toStringAsFixed(1)} L',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14213D),
              ),
            ),
            Text(
              '₹${amount.round()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF087F73),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateMemberLoginDialog(Map<String, dynamic> member) {
    final code = member['id'].toString();
    final defaultUser =
        member['name'].toString().toLowerCase().split(' ').first;
    final usernameController = TextEditingController(text: defaultUser);
    final passwordController = TextEditingController(text: 'password');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.phone_android_rounded, color: Color(0xFF087F73)),
            SizedBox(width: 8),
            Text(
              'Member Mobile Login',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provision mobile app credentials for ${member['name']} (#$code). The farmer can log in on their phone to view their passbook & payment bills.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF087F73),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final user = usernameController.text.trim();
              final pass = passwordController.text.trim();
              if (user.isEmpty || pass.isEmpty) return;
              Navigator.pop(ctx);
              await ApiService.createMemberLogin(code, user, pass);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mobile login credentials saved for ${member['name']}: $user / $pass',
                    ),
                    backgroundColor: const Color(0xFF087F73),
                  ),
                );
              }
            },
            child: const Text('Save Credentials'),
          ),
        ],
      ),
    );
  }
}
