import 'package:flutter/material.dart';

import 'add_payment_screen.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/receipt_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() =>
      _PaymentsScreenState();
}

class _PaymentsScreenState
    extends State<PaymentsScreen> {

  // =============================================================
  // PAYMENT CYCLE
  // =============================================================

  String selectedCycle = 'Monthly';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final data = await ApiService.getPayments(selectedCycle);
      if (mounted) {
        setState(() {
          final existingIds = payments.map((p) => p['id'].toString()).toSet();
          for (final item in data) {
            final id = item['id'] ?? item['_id'] ?? 1;
            if (!existingIds.contains(id.toString())) {
              payments.add({
                'id': id,
                'member': item['memberName'] ?? item['member'] ?? 'Member',
                'animal': item['animal'] ?? 'Cow',
                'milk': item['totalMilk'] != null ? '${item['totalMilk']} L' : '—',
                'gross': (item['grossAmount'] as num?)?.toDouble() ?? 0.0,
                'advance': (item['advanceDeduction'] as num?)?.toDouble() ?? 0.0,
                'deduction': (item['otherDeductions'] as num?)?.toDouble() ?? 0.0,
                'amount': (item['netPayable'] ?? item['amount'] as num?)?.toDouble() ?? 0.0,
                'status': item['status'] ?? 'Paid',
                'method': item['paymentMode'] ?? item['method'] ?? 'Cash',
                'cycle': item['cycle'] ?? selectedCycle,
                'date': item['date'] ?? 'Today',
              });
            }
          }
        });
      }
    } catch (_) {}
  }

  // =============================================================
  // SEARCH
  // =============================================================

  final TextEditingController searchController =
  TextEditingController();

  // =============================================================
  // FILTER
  // =============================================================

  String selectedFilter = 'All';

  // =============================================================
  // PAYMENT DATA
  // =============================================================

  final List<Map<String, dynamic>> payments = [];

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =============================================================
  // CYCLE PAYMENTS
  // =============================================================

  List<Map<String, dynamic>> get cyclePayments {
    final sel = selectedCycle.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return payments.where((p) {
      final c = (p['cycle'] ?? '').toString().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
      return c.isEmpty || c == sel || c.contains(sel) || sel.contains(c);
    }).toList();
  }

  // =============================================================
  // FILTERED PAYMENTS
  // =============================================================

  List<Map<String, dynamic>> get filteredPayments {
    final query =
    searchController.text.trim().toLowerCase();

    return cyclePayments.where((payment) {

      final member =
      payment['member']
          .toString()
          .toLowerCase();

      final matchesSearch =
          query.isEmpty ||
              member.contains(query);

      final matchesFilter =
          selectedFilter == 'All' ||
              payment['status'] ==
                  selectedFilter;

      return matchesSearch &&
          matchesFilter;
    }).toList();
  }

  // =============================================================
  // SUMMARY VALUES
  // =============================================================

  double get totalPayable {
    return cyclePayments.fold(
      0.0,
          (sum, payment) =>
      sum + (payment['amount'] as double),
    );
  }

  double get paidAmount {
    return cyclePayments
        .where(
          (payment) =>
      payment['status'] == 'Paid',
    )
        .fold(
      0.0,
          (sum, payment) =>
      sum +
          (payment['amount'] as double),
    );
  }

  double get pendingAmount {
    return cyclePayments
        .where(
          (payment) =>
      payment['status'] == 'Pending',
    )
        .fold(
      0.0,
          (sum, payment) =>
      sum +
          (payment['amount'] as double),
    );
  }

  int get paidMembers {
    return cyclePayments
        .where(
          (payment) =>
      payment['status'] == 'Paid',
    )
        .length;
  }

  // =============================================================
  // OPEN ADD PAYMENT
  // =============================================================

  Future<void> _openAddPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddPaymentScreen(
              onSave: (payment) {
                final paymentCycle = payment['cycle']?.toString() ?? selectedCycle;
                final newRecord = {
                  'id': payment['id'] ?? DateTime.now().millisecondsSinceEpoch,
                  'member': payment['member'],
                  'memberCode': payment['memberCode'] ?? payment['memberId'] ?? 'M001',
                  'animal': payment['animal'] ?? 'Cow',
                  'milk': payment['milk'] ?? '—',
                  'gross': payment['amount'],
                  'advance': 0.0,
                  'deduction': 0.0,
                  'amount': payment['amount'],
                  'status': payment['status'] ?? 'Paid',
                  'method': payment['method'] ?? 'Cash',
                  'cycle': paymentCycle,
                  'date': _formatDate(
                    payment['date'],
                  ),
                };

                setState(() {
                  selectedCycle = paymentCycle;
                  selectedFilter = 'All';
                  payments.insert(0, newRecord);
                });

                final payload = {
                  'memberCode': payment['memberCode'] ?? payment['memberId'] ?? 'M001',
                  'memberName': payment['member'],
                  'cycle': paymentCycle,
                  'grossAmount': (payment['amount'] as num).toDouble(),
                  'advanceDeduction': 0.0,
                  'otherDeductions': 0.0,
                  'netPayable': (payment['amount'] as num).toDouble(),
                  'paymentMode': payment['method'] ?? 'Cash',
                  'status': payment['status'] ?? 'Paid',
                  'date': _formatDate(payment['date']),
                };

                ApiService.createPayment(payload).then((res) {
                  if (res == null) SyncService.enqueue('payment', payload);
                }).catchError((_) {
                  SyncService.enqueue('payment', payload);
                });
              },
            ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Payment saved successfully',
          ),
          backgroundColor:
          Color(0xFF087F73),
        ),
      );
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF8FAFA),

      // =========================================================
      // APP BAR
      // =========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF14213D),
            size: 20,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Text(
              'Payments',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14213D),
              ),
            ),

            Text(
              'Manage member payments',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF7A869A),
              ),
            ),
          ],
        ),
      ),

      // =========================================================
      // BODY
      // =========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            100,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // =================================================
              // PAYMENT CYCLE
              // =================================================

              _sectionTitle(
                'Payment Cycle',
              ),

              const SizedBox(height: 10),

              _cycleSelector(),

              const SizedBox(height: 22),

              // =================================================
              // PAYMENT SUMMARY
              // =================================================

              _sectionTitle(
                'Payment Summary',
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,

                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                mainAxisSpacing: 10,

                crossAxisSpacing: 10,

                childAspectRatio: 1.35,

                children: [

                  _summaryCard(
                    icon:
                    Icons.receipt_long_outlined,

                    title:
                    'Total Payable',

                    value:
                    '₹${totalPayable.toStringAsFixed(0)}',

                    iconColor:
                    const Color(
                      0xFF087F73,
                    ),
                  ),

                  _summaryCard(
                    icon:
                    Icons.check_circle_outline,

                    title: 'Paid',

                    value:
                    '₹${paidAmount.toStringAsFixed(0)}',

                    iconColor:
                    const Color(
                      0xFF55A85B,
                    ),
                  ),

                  _summaryCard(
                    icon:
                    Icons.pending_actions_outlined,

                    title: 'Pending',

                    value:
                    '₹${pendingAmount.toStringAsFixed(0)}',

                    iconColor:
                    const Color(
                      0xFFFF9800,
                    ),
                  ),

                  _summaryCard(
                    icon:
                    Icons.groups_outlined,

                    title:
                    'Paid Members',

                    value:
                    '$paidMembers',

                    iconColor:
                    const Color(
                      0xFF4F6BED,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // =================================================
              // MEMBER PAYMENTS
              // =================================================

              _sectionTitle(
                'Member Payments',
              ),

              const SizedBox(height: 12),

              // SEARCH
              TextField(
                controller: searchController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration:
                InputDecoration(
                  hintText:
                  'Search member',

                  hintStyle:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF98A2B3),
                  ),

                  prefixIcon:
                  const Icon(
                    Icons.search_rounded,
                    color:
                    Color(0xFF667085),
                    size: 21,
                  ),

                  filled: true,

                  fillColor:
                  Colors.white,

                  contentPadding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 14,
                  ),

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),

                    borderSide:
                    const BorderSide(
                      color:
                      Color(0xFFE1E5EA),
                    ),
                  ),

                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),

                    borderSide:
                    const BorderSide(
                      color:
                      Color(0xFFE1E5EA),
                    ),
                  ),

                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),

                    borderSide:
                    const BorderSide(
                      color:
                      Color(0xFF087F73),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // FILTER BUTTONS
              // =================================================

              _filterSelector(),

              const SizedBox(height: 14),

              // =================================================
              // PAYMENT LIST
              // =================================================

              if (filteredPayments.isEmpty)
                _emptyState()
              else
                ...filteredPayments.map(
                      (payment) =>
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),

                        child:
                        _paymentCard(payment),
                      ),
                ),
            ],
          ),
        ),
      ),

      // =========================================================
      // ADD PAYMENT BUTTON
      // =========================================================

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _openAddPayment,

        backgroundColor:
        const Color(0xFF087F73),

        foregroundColor:
        Colors.white,

        elevation: 4,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          'Add Payment',
          style: TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        fontSize: 16,
        fontWeight:
        FontWeight.w700,
        color:
        Color(0xFF14213D),
      ),
    );
  }

  // =============================================================
  // CYCLE SELECTOR
  // =============================================================

  Widget _cycleSelector() {
    final cycles = [
      '10 Days',
      '15 Days',
      'Monthly',
    ];

    return Container(
      height: 48,

      padding:
      const EdgeInsets.all(4),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          13,
        ),

        border: Border.all(
          color:
          const Color(0xFFE1E5EA),
        ),
      ),

      child: Row(
        children:
        cycles.map((cycle) {
          final selected =
              selectedCycle ==
                  cycle;

          return Expanded(
            child:
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedCycle =
                      cycle;
                });
              },

              child:
              AnimatedContainer(
                duration:
                const Duration(
                  milliseconds:
                  180,
                ),

                alignment:
                Alignment.center,

                decoration:
                BoxDecoration(
                  color: selected
                      ? const Color(
                    0xFFDDF3EF,
                  )
                      : Colors
                      .transparent,

                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),

                child: Text(
                  cycle,

                  style:
                  TextStyle(
                    fontSize: 11,

                    fontWeight:
                    selected
                        ? FontWeight
                        .w700
                        : FontWeight
                        .w400,

                    color: selected
                        ? const Color(
                      0xFF087F73,
                    )
                        : const Color(
                      0xFF667085,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =============================================================
  // SUMMARY CARD
  // =============================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(12),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color:
          const Color(0xFFE1E5EA),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,

                decoration:
                BoxDecoration(
                  color:
                  iconColor.withValues(alpha: 
                    0.10,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),

                child: Icon(
                  icon,
                  size: 18,
                  color:
                  iconColor,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons
                    .chevron_right_rounded,
                size: 18,
                color:
                Color(0xFF98A2B3),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            title,

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(
              fontSize: 10,
              color:
              Color(0xFF7A869A),
            ),
          ),

          const SizedBox(height: 3),

          Flexible(
            child: Text(
              value,

              maxLines: 1,

              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF14213D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FILTER SELECTOR
  // =============================================================

  Widget _filterSelector() {
    final filters = [
      'All',
      'Paid',
      'Pending',
    ];

    return Row(
      children:
      filters.map((filter) {
        final selected =
            selectedFilter ==
                filter;

        return Padding(
          padding:
          const EdgeInsets.only(
            right: 8,
          ),

          child:
          GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter =
                    filter;
              });
            },

            child:
            AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 180,
              ),

              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 18,
                vertical: 8,
              ),

              decoration:
              BoxDecoration(
                color: selected
                    ? const Color(
                  0xFF087F73,
                )
                    : Colors.white,

                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),

                border: Border.all(
                  color: selected
                      ? const Color(
                    0xFF087F73,
                  )
                      : const Color(
                    0xFFE1E5EA,
                  ),
                ),
              ),

              child: Text(
                filter,

                style:
                TextStyle(
                  fontSize: 11,

                  fontWeight:
                  selected
                      ? FontWeight
                      .w600
                      : FontWeight
                      .w400,

                  color: selected
                      ? Colors.white
                      : const Color(
                    0xFF667085,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =============================================================
  // PAYMENT CARD
  // =============================================================

  Widget _paymentCard(
      Map<String, dynamic> payment) {

    final bool paid =
        payment['status'] ==
            'Paid';

    final Color statusColor =
    paid
        ? const Color(
      0xFF55A85B,
    )
        : const Color(
      0xFFFF9800,
    );

    final Color statusBg =
    paid
        ? const Color(
      0xFFEAF7EC,
    )
        : const Color(
      0xFFFFF3E0,
    );

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(13),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          15,
        ),

        border: Border.all(
          color:
          const Color(0xFFE1E5EA),
        ),
      ),

      child: Column(
        children: [

          // =====================================================
          // MEMBER HEADER
          // =====================================================

          Row(
            children: [

              Container(
                width: 42,
                height: 42,

                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE7F6F3,
                  ),

                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  payment['animal'] ==
                      'Cow'
                      ? Icons
                      .agriculture_outlined
                      : Icons
                      .agriculture,

                  color:
                  const Color(
                    0xFF087F73,
                  ),

                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Text(
                      payment[
                      'member'],

                      maxLines: 1,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(
                          0xFF14213D,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${payment['animal']} • ${payment['milk']}',

                      style:
                      const TextStyle(
                        fontSize: 10,
                        color:
                        Color(
                          0xFF7A869A,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                BoxDecoration(
                  color:
                  statusBg,

                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child: Text(
                  payment[
                  'status'],

                  style:
                  TextStyle(
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =====================================================
          // DETAILS
          // =====================================================

          Row(
            children: [
              _detailItem(
                'Gross',
                '₹${payment['gross'].toStringAsFixed(0)}',
              ),

              _detailItem(
                'Advance',
                '₹${payment['advance'].toStringAsFixed(0)}',
              ),

              _detailItem(
                'Deduction',
                '₹${payment['deduction'].toStringAsFixed(0)}',
              ),

              _detailItem(
                'Payable',
                '₹${payment['amount'].toStringAsFixed(0)}',
                highlight: true,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =====================================================
          // FOOTER
          // =====================================================

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color:
                Color(0xFF98A2B3),
              ),

              const SizedBox(width: 5),

              Text(
                payment['date'],

                style:
                const TextStyle(
                  fontSize: 10,
                  color:
                  Color(0xFF7A869A),
                ),
              ),

              const Spacer(),

              InkWell(
                onTap: () {
                  ReceiptService.showPaymentSlipDialog(
                    context,
                    dairyName: 'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur',
                    billNo: 'PAY-${payment['id'] ?? '001'}',
                    memberCode: payment['memberId'] ?? 'M001',
                    memberName: payment['name'] ?? 'Member',
                    cycle: payment['cycle'] ?? selectedCycle,
                    totalMilk: (payment['milk'] as num?)?.toDouble() ?? 0.0,
                    grossAmount: (payment['gross'] as num?)?.toDouble() ?? 0.0,
                    advanceDeduction: (payment['advance'] as num?)?.toDouble() ?? 0.0,
                    otherDeductions: (payment['deduction'] as num?)?.toDouble() ?? 0.0,
                    netPayable: (payment['amount'] as num?)?.toDouble() ?? 0.0,
                    paymentMode: payment['method'] ?? 'Bank',
                    status: payment['status'] ?? 'Paid',
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F6F3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF087F73)),
                      SizedBox(width: 4),
                      Text(
                        'Slip',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF087F73),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                payment['method'],

                style:
                const TextStyle(
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF087F73),
                ),
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
      String value, {
        bool highlight = false,
      }) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            title,

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(
              fontSize: 8,
              color:
              Color(0xFF98A2B3),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 10,

              fontWeight:
              FontWeight.w600,

              color: highlight
                  ? const Color(
                0xFF087F73,
              )
                  : const Color(
                0xFF344054,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF087F73).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF087F73),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Farmer Payments for this Cycle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record member payouts, cash disbursements, or bank transfers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A869A),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _openAddPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF087F73),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Record First Payment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // DATE FORMAT
  // =============================================================

  String _formatDate(DateTime date) {
    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}