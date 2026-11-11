import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/sync_service.dart';

class AdvanceScreen extends StatefulWidget {
  const AdvanceScreen({super.key});

  @override
  State<AdvanceScreen> createState() => _AdvanceScreenState();
}

class _AdvanceScreenState extends State<AdvanceScreen> {
  final TextEditingController searchController =
  TextEditingController();

  String searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    try {
      final data = await ApiService.getAdvances();
      final membersData = await ApiService.getMembers();
      if (mounted) {
        setState(() {
          advances.clear();
          for (final item in data) {
            advances.add({
              'id': item['id'],
              'member': item['memberName'] ?? item['member'] ?? 'Member',
              'memberId': item['memberCode'] ?? item['memberId'] ?? 'M001',
              'amount': (item['amount'] as num?)?.toDouble() ?? 0.0,
              'recovered': (item['recovered'] as num?)?.toDouble() ?? 0.0,
              'date': item['date'] ?? 'Today',
              'reason': item['reason'] ?? 'General',
              'status': item['status'] ?? 'Pending',
            });
          }
          members.clear();
          for (final m in membersData) {
            members.add({
              'name': (m['name'] ?? m['farmerName'] ?? '').toString(),
              'id': (m['memberCode'] ?? m['id'] ?? '').toString(),
            });
          }
        });
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> advances = [];

  final List<Map<String, String>> members = [];

  List<Map<String, dynamic>> get filteredAdvances {
    if (searchQuery.trim().isEmpty) {
      return advances;
    }

    return advances.where((advance) {
      final name =
      advance['member'].toString().toLowerCase();

      final id =
      advance['memberId'].toString().toLowerCase();

      final query = searchQuery.toLowerCase();

      return name.contains(query) || id.contains(query);
    }).toList();
  }

  double get totalAdvance {
    return advances.fold(
      0,
          (sum, item) => sum + (item['amount'] as double),
    );
  }

  double get totalRecovered {
    return advances.fold(
      0,
          (sum, item) => sum + (item['recovered'] as double),
    );
  }

  double get totalPending {
    return totalAdvance - totalRecovered;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),

      // =========================================================
      // APP BAR
      // =========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF14213D),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Advance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14213D),
          ),
        ),
      ),

      // =========================================================
      // ADD ADVANCE BUTTON
      // =========================================================

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF087F73),
        foregroundColor: Colors.white,
        elevation: 3,

        onPressed: _showAddAdvanceSheet,

        icon: const Icon(Icons.add),

        label: const Text(
          'Add Advance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =========================================================
      // BODY
      // =========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          100,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // SUMMARY
            // =====================================================

            _buildSummaryCard(),

            const SizedBox(height: 22),

            // =====================================================
            // SEARCH
            // =====================================================

            _buildSearch(),

            const SizedBox(height: 22),

            // =====================================================
            // HISTORY TITLE
            // =====================================================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Advance History',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF14213D),
                  ),
                ),

                Text(
                  '${filteredAdvances.length} Records',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A869A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =====================================================
            // ADVANCE LIST
            // =====================================================

            ...filteredAdvances.map(
                  (advance) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildAdvanceCard(advance),
              ),
            ),

            if (filteredAdvances.isEmpty)
              _buildEmptyState(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
      },
    );
  }

  // =============================================================
  // SUMMARY CARD
  // =============================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE5E9E8),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Advance Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  icon: Icons.currency_rupee_rounded,
                  title: 'Total Advance',
                  value:
                  '₹${totalAdvance.toStringAsFixed(0)}',
                  iconColor:
                  const Color(0xFF087F73),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryItem(
                  icon: Icons.check_circle_outline,
                  title: 'Recovered',
                  value:
                  '₹${totalRecovered.toStringAsFixed(0)}',
                  iconColor:
                  const Color(0xFF55A85B),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryItem(
                  icon: Icons.pending_outlined,
                  title: 'Pending',
                  value:
                  '₹${totalPending.toStringAsFixed(0)}',
                  iconColor:
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SUMMARY ITEM
  // =============================================================

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color: iconColor,
            size: 21,
          ),

          const SizedBox(height: 7),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7A869A),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  // =============================================================
  // SEARCH
  // =============================================================

  Widget _buildSearch() {
    return TextField(
      controller: searchController,

      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },

      decoration: InputDecoration(
        hintText: 'Search member or member ID...',
        hintStyle: const TextStyle(
          color: Color(0xFF98A2B3),
          fontSize: 13,
        ),

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF087F73),
        ),

        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(
            Icons.clear,
            size: 19,
          ),
          onPressed: () {
            searchController.clear();

            setState(() {
              searchQuery = '';
            });
          },
        )
            : null,

        filled: true,
        fillColor: Colors.white,

        contentPadding:
        const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE3E7E6),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE3E7E6),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF087F73),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ADVANCE CARD
  // =============================================================

  Widget _buildAdvanceCard(
      Map<String, dynamic> advance,
      ) {
    final double amount =
    advance['amount'] as double;

    final double recovered =
    advance['recovered'] as double;

    final double pending =
        amount - recovered;

    final bool isRecovered =
        advance['status'] == 'Recovered';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE5E9E8),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              // =================================================
              // MEMBER ICON
              // =================================================

              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6F3),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF087F73),
                ),
              ),

              const SizedBox(width: 11),

              // =================================================
              // MEMBER
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      advance['member'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14213D),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${advance['memberId']} • ${advance['date']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // STATUS
              // =================================================

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: isRecovered
                      ? const Color(0xFFEAF7EC)
                      : const Color(0xFFFFF4DF),

                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: Text(
                  advance['status'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isRecovered
                        ? const Color(0xFF3C9145)
                        : const Color(0xFFE58A00),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(
            height: 1,
            color: Color(0xFFEEF1F0),
          ),

          const SizedBox(height: 12),

          // =====================================================
          // DETAILS
          // =====================================================

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  'Advance',
                  '₹${amount.toStringAsFixed(0)}',
                ),
              ),

              Expanded(
                child: _detailItem(
                  'Recovered',
                  '₹${recovered.toStringAsFixed(0)}',
                ),
              ),

              Expanded(
                child: _detailItem(
                  'Pending',
                  '₹${pending.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 15,
                color: Color(0xFF7A869A),
              ),

              const SizedBox(width: 6),

              Text(
                'Reason: ${advance['reason']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF667085),
                ),
              ),

              const Spacer(),

              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                const BoxConstraints(),

                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Color(0xFF7A869A),
                ),

                onPressed: () {
                  _showAdvanceOptions(advance);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // DETAIL ITEM
  // =============================================================

  Widget _detailItem(
      String title,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF7A869A),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14213D),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _buildEmptyState() {
    final bool isSearch = searchQuery.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E9E8),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF087F73).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.currency_rupee_rounded,
              size: 34,
              color: const Color(0xFF087F73),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSearch ? 'No advance records found'.tr : 'No Cash Advances Issued'.tr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try searching with another member name or ID.'.tr
                : 'Issue cash advances or loans to dairy farmers to track recovery.'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7A869A),
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _showAddAdvanceSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087F73),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Issue First Advance'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // ADD ADVANCE SHEET
  // =============================================================

  void _showAddAdvanceSheet() {
    String? selectedMember;
    String selectedReason = 'Personal';
    String selectedDate = '22 Aug 2026';

    final amountController =
    TextEditingController();

    final noteController =
    TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),

              child: Container(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  25,
                ),

                decoration:
                const BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      // =========================================
                      // HANDLE
                      // =========================================

                      Center(
                        child: Container(
                          height: 4,
                          width: 40,

                          decoration:
                          BoxDecoration(
                            color: Colors
                                .grey.shade300,
                            borderRadius:
                            BorderRadius.circular(
                              5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Add Advance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF14213D),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Enter advance details for the member.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Color(0xFF7A869A),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================================
                      // MEMBER
                      // =========================================

                      DropdownButtonFormField<
                          String>(
                        initialValue: selectedMember,

                        decoration:
                        _dropdownDecoration(
                          'Select Member',
                        ),

                        items: members
                            .map(
                              (member) =>
                              DropdownMenuItem<
                                  String>(
                                value:
                                member['name'],
                                child: Text(
                                  '${member['name']} (${member['id']})',
                                ),
                              ),
                        )
                            .toList(),

                        onChanged: (value) {
                          setSheetState(() {
                            selectedMember =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // =========================================
                      // AMOUNT
                      // =========================================

                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: ValidationUtils.decimalNumberFormatter,

                        decoration:
                        _inputDecoration(
                          label: 'Advance Amount',
                          hint: 'Enter amount',
                          prefix: '₹ ',
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================
                      // REASON
                      // =========================================

                      DropdownButtonFormField<
                          String>(
                        initialValue: selectedReason,

                        decoration:
                        _dropdownDecoration(
                          'Reason',
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'Personal',
                            child:
                            Text('Personal'),
                          ),
                          DropdownMenuItem(
                            value: 'Medical',
                            child:
                            Text('Medical'),
                          ),
                          DropdownMenuItem(
                            value: 'Household',
                            child:
                            Text('Household'),
                          ),
                          DropdownMenuItem(
                            value: 'Emergency',
                            child:
                            Text('Emergency'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],

                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            selectedReason =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // =========================================
                      // DATE
                      // =========================================

                      TextField(
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: 'Date',
                          hint: selectedDate,
                          suffix: Icons.calendar_today_outlined,
                        ),
                        controller: TextEditingController(text: selectedDate),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: DateTime.now(),
                          );

                          if (date != null) {
                            const months = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ];
                            setSheetState(() {
                              selectedDate =
                                  '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      // =========================================
                      // NOTE
                      // =========================================

                      TextField(
                        controller:
                        noteController,

                        maxLines: 2,

                        decoration:
                        _inputDecoration(
                          label: 'Notes',
                          hint:
                          'Optional notes...',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================================
                      // SAVE
                      // =========================================

                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child:
                        ElevatedButton(
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xFF087F73,
                            ),

                            foregroundColor:
                            Colors.white,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                13,
                              ),
                            ),
                          ),

                          onPressed: () {
                            if (selectedMember ==
                                null ||
                                amountController
                                    .text
                                    .trim()
                                    .isEmpty) {
                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a member and enter amount.',
                                  ),
                                ),
                              );

                              return;
                            }

                            final amount =
                            double.tryParse(
                              amountController
                                  .text
                                  .trim(),
                            );

                            if (amount == null ||
                                amount <= 0) {
                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid amount.',
                                  ),
                                ),
                              );

                              return;
                            }

                            final member =
                            members.firstWhere(
                                  (item) =>
                              item['name'] ==
                                  selectedMember,
                            );

                            setState(() {
                              advances.insert(
                                0,
                                {
                                  'member':
                                  member['name'],
                                  'memberId':
                                  member['id'],
                                  'amount': amount,
                                  'recovered':
                                  0.0,
                                  'date':
                                  selectedDate,
                                  'reason':
                                  selectedReason,
                                  'status':
                                  'Pending',
                                },
                              );
                            });

                            final advancePayload = {
                              'memberCode': member['id'],
                              'memberName': member['name'],
                              'amount': amount,
                              'recovered': 0.0,
                              'date': selectedDate,
                              'reason': selectedReason,
                              'status': 'Pending',
                            };

                            ApiService.createAdvance(advancePayload).then((res) {
                              if (res == null) {
                                SyncService.enqueue('advance', advancePayload);
                              }
                            }).catchError((_) {
                              SyncService.enqueue('advance', advancePayload);
                            });

                            Navigator.pop(
                              sheetContext,
                            );

                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Advance added successfully',
                                ),
                                backgroundColor:
                                Color(
                                  0xFF087F73,
                                ),
                              ),
                            );
                          },

                          child: const Text(
                            'SAVE ADVANCE',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing:
                              0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =============================================================
  // ADVANCE OPTIONS
  // =============================================================

  void _showAdvanceOptions(
      Map<String, dynamic> advance,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,

      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(
                leading: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF087F73),
                ),

                title: const Text(
                  'View Details',
                ),

                onTap: () {
                  Navigator.pop(context);

                  _showAdvanceDetails(
                    advance,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF55A85B),
                ),
                title: const Text('Record Repayment'),
                subtitle: const Text('Add repayment towards this advance'),
                onTap: () {
                  Navigator.pop(context);
                  _showRepaymentDialog(advance);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                ),

                title: const Text(
                  'Edit Advance',
                ),

                onTap: () {
                  Navigator.pop(context);
                  _showEditAdvanceSheet(advance);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),

                title: const Text(
                  'Delete Advance',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),

                onTap: () {
                  Navigator.pop(context);

                  _deleteAdvance(advance);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // DETAILS
  // =============================================================

  void _showAdvanceDetails(
      Map<String, dynamic> advance,
      ) {
    final amount =
    advance['amount'] as double;

    final recovered =
    advance['recovered'] as double;

    final pending =
        amount - recovered;

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Advance Details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              _dialogDetail(
                'Member',
                advance['member'],
              ),

              _dialogDetail(
                'Member ID',
                advance['memberId'],
              ),

              _dialogDetail(
                'Amount',
                '₹${amount.toStringAsFixed(0)}',
              ),

              _dialogDetail(
                'Recovered',
                '₹${recovered.toStringAsFixed(0)}',
              ),

              _dialogDetail(
                'Pending',
                '₹${pending.toStringAsFixed(0)}',
              ),

              _dialogDetail(
                'Date',
                advance['date'],
              ),

              _dialogDetail(
                'Reason',
                advance['reason'],
              ),

              _dialogDetail(
                'Status',
                advance['status'],
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Color(0xFF087F73),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // DELETE
  // =============================================================

  void _deleteAdvance(
      Map<String, dynamic> advance,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Advance?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          content: Text(
            'Are you sure you want to delete the advance for ${advance['member']}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'CANCEL',
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  advances.remove(advance);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Advance deleted successfully',
                    ),
                  ),
                );
              },

              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRepaymentDialog(Map<String, dynamic> advance) {
    final amount = advance['amount'] as double;
    final recovered = advance['recovered'] as double;
    final pending = amount - recovered;

    if (pending <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This advance has already been fully recovered.')),
      );
      return;
    }

    final repaymentController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Record Repayment', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF14213D))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: ${advance['member']} (${advance['memberId']})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Current Pending: ₹${pending.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: repaymentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: ValidationUtils.decimalNumberFormatter,
              decoration: _inputDecoration(
                label: 'Repayment Amount',
                hint: 'Max ₹${pending.toStringAsFixed(0)}',
                prefix: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF7A869A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF087F73), foregroundColor: Colors.white),
            onPressed: () {
              final repAmt = double.tryParse(repaymentController.text.trim());
              if (repAmt == null || repAmt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid repayment amount.')),
                );
                return;
              }
              if (repAmt > pending) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Amount cannot exceed pending ₹${pending.toStringAsFixed(0)}.')),
                );
                return;
              }
              setState(() {
                advance['recovered'] = recovered + repAmt;
                if ((advance['recovered'] as double) >= (advance['amount'] as double)) {
                  advance['status'] = 'Recovered';
                }
              });
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Repayment of ₹${repAmt.toStringAsFixed(0)} recorded successfully!'),
                  backgroundColor: const Color(0xFF087F73),
                ),
              );
            },
            child: const Text('RECORD'),
          ),
        ],
      ),
    );
  }

  void _showEditAdvanceSheet(Map<String, dynamic> advance) {
    String selectedReason = advance['reason'];
    String selectedDate = advance['date'];
    final amountController = TextEditingController(text: (advance['amount'] as double).toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Edit Advance — ${advance['member']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF14213D))),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: ValidationUtils.decimalNumberFormatter,
                        decoration: _inputDecoration(label: 'Total Advance Amount', hint: 'Enter amount', prefix: '₹ '),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedReason,
                        decoration: _dropdownDecoration('Reason'),
                        items: const [
                          DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                          DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                          DropdownMenuItem(value: 'Household', child: Text('Household')),
                          DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedReason = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        readOnly: true,
                        decoration: _inputDecoration(label: 'Date', hint: selectedDate, suffix: Icons.calendar_today_outlined),
                        controller: TextEditingController(text: selectedDate),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: DateTime.now(),
                          );
                          if (date != null) {
                            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            setSheetState(() {
                              selectedDate = '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF087F73),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          onPressed: () {
                            final newAmount = double.tryParse(amountController.text.trim());
                            if (newAmount == null || newAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid amount.')),
                              );
                              return;
                            }
                            final recovered = advance['recovered'] as double;
                            if (newAmount < recovered) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Amount cannot be less than already recovered ₹${recovered.toStringAsFixed(0)}.')),
                              );
                              return;
                            }
                            setState(() {
                              advance['amount'] = newAmount;
                              advance['reason'] = selectedReason;
                              advance['date'] = selectedDate;
                              advance['status'] = recovered >= newAmount ? 'Recovered' : 'Pending';
                            });
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Advance updated successfully'), backgroundColor: Color(0xFF087F73)),
                            );
                          },
                          child: const Text('UPDATE ADVANCE', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =============================================================
  // DIALOG DETAIL
  // =============================================================

  Widget _dialogDetail(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 90,

            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A869A),
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14213D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // INPUT DECORATION
  // =============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    String? prefix,
    IconData? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,

      suffixIcon: suffix != null
          ? Icon(
        suffix,
        size: 19,
        color: const Color(0xFF7A869A),
      )
          : null,

      filled: true,
      fillColor: const Color(0xFFF8FAFA),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE1E6E5),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE1E6E5),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF087F73),
          width: 1.4,
        ),
      ),
    );
  }

  // =============================================================
  // DROPDOWN DECORATION
  // =============================================================

  InputDecoration _dropdownDecoration(
      String label,
      ) {
    return InputDecoration(
      labelText: label,

      filled: true,
      fillColor: const Color(0xFFF8FAFA),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE1E6E5),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE1E6E5),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF087F73),
          width: 1.4,
        ),
      ),
    );
  }
}