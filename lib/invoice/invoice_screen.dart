import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/language_service.dart';
import 'detailed_bill_statement_screen.dart';
import '../widgets/pdf_download_dialog.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color secondaryText = Color(0xFF7A869A);
  static const Color background = Color(0xFFF8FAFA);

  late TabController _tabController;
  bool _isLoading = false;

  String? selectedMember;
  String selectedCycle = '10 Days';

  final TextEditingController milkController = TextEditingController();
  final TextEditingController grossController = TextEditingController();
  final TextEditingController advanceController = TextEditingController();
  final TextEditingController deductionController = TextEditingController();

  final List<String> members = [];

  final List<String> cycles = [
    '10 Days',
    '15 Days',
    'Monthly',
  ];

  final List<Map<String, dynamic>> _invoicesHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: ApiService.userRole.toUpperCase() == 'MEMBER' ? 1 : 0,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final membersData = await ApiService.getMembers();
      final data = await ApiService.getInvoices();
      if (mounted) {
        setState(() {
          members.clear();
          for (var m in membersData) {
            final name = (m['name'] ?? m['farmerName'] ?? '').toString();
            if (name.isNotEmpty) members.add(name);
          }
          if (members.isNotEmpty) {
            if (selectedMember == null || !members.contains(selectedMember)) {
              selectedMember = members.first;
            }
          } else {
            selectedMember = null;
          }

          _invoicesHistory.clear();
          for (var item in data) {
            _invoicesHistory.add({
              'id': item['id'],
              'invoiceNo': item['invoiceNumber'] ?? item['invoiceNo'] ?? 'INV-${item['id'] ?? '001'}',
              'member': item['memberName'] ?? item['member'] ?? 'Farmer',
              'cycle': item['cycle'] ?? item['billingCycle'] ?? '10 Days',
              'milk': (item['totalLiters'] ?? item['milk'] ?? 0).toDouble(),
              'gross': (item['grossAmount'] ?? item['gross'] ?? 0).toDouble(),
              'advance': (item['advanceRecovery'] ?? item['advance'] ?? 0).toDouble(),
              'deduction': (item['deductions'] ?? item['deduction'] ?? 0).toDouble(),
              'net': (item['netAmount'] ?? item['net'] ?? 0).toDouble(),
              'date': item['date'] ?? 'Recent',
              'status': item['status'] ?? 'Pending',
            });
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    milkController.dispose();
    grossController.dispose();
    advanceController.dispose();
    deductionController.dispose();
    super.dispose();
  }

  double get netPayable {
    final gross = double.tryParse(grossController.text) ?? 0;
    final advance = double.tryParse(advanceController.text) ?? 0;
    final deduction = double.tryParse(deductionController.text) ?? 0;
    final result = gross - advance - deduction;
    return result < 0 ? 0 : result;
  }

  void _generateInvoice() {
    if (selectedMember == null || selectedMember!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register and select a member first.')),
      );
      return;
    }
    final gross = double.tryParse(grossController.text) ?? 0;
    final advance = double.tryParse(advanceController.text) ?? 0;
    final deduction = double.tryParse(deductionController.text) ?? 0;
    final milk = double.tryParse(milkController.text) ?? 0;

    final newInvoice = {
      'invoiceNo': 'INV-2026-0${_invoicesHistory.length + 82}',
      'invoiceNumber': 'INV-2026-0${_invoicesHistory.length + 82}',
      'member': selectedMember,
      'memberName': selectedMember,
      'cycle': '$selectedCycle (Current)',
      'billingCycle': selectedCycle,
      'milk': milk,
      'totalLiters': milk,
      'gross': gross,
      'grossAmount': gross,
      'advance': advance,
      'advanceRecovery': advance,
      'deduction': deduction,
      'deductions': deduction,
      'net': netPayable,
      'netAmount': netPayable,
      'date': 'Today',
      'status': 'Pending',
    };

    setState(() {
      _invoicesHistory.insert(0, newInvoice);
    });

    ApiService.createInvoice(newInvoice).then((res) {
      if (res == null) {
        SyncService.enqueue('invoice', newInvoice);
      }
    });

    _showInvoiceSlipModal(newInvoice);
  }

  void _showInvoiceSlipModal(Map<String, dynamic> invoice) {
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
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Slip Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E9E8)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'MEMBER PAYMENT BILL / INVOICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      _slipRow('Bill / Invoice No', invoice['invoiceNo']),
                      const SizedBox(height: 6),
                      _slipRow('Member Name', invoice['member']),
                      const SizedBox(height: 6),
                      _slipRow('Billing Cycle', invoice['cycle']),
                      const SizedBox(height: 6),
                      _slipRow('Bill Date', invoice['date']),
                      const SizedBox(height: 6),
                      _slipRow(
                        'Status',
                        invoice['status'],
                        valueColor: invoice['status'] == 'Paid'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E9E8)),
                  ),
                  child: Column(
                    children: [
                      _slipRow(
                        'Total Milk Supplied',
                        '${invoice['milk']} Ltr',
                      ),
                      const SizedBox(height: 8),
                      _slipRow(
                        'Gross Milk Amount',
                        '₹${(invoice['gross'] as double).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _slipRow(
                        'Less: Advance Recovery',
                        '- ₹${(invoice['advance'] as double).toStringAsFixed(2)}',
                        valueColor: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      _slipRow(
                        'Less: Other Deductions',
                        '- ₹${(invoice['deduction'] as double).toStringAsFixed(2)}',
                        valueColor: Colors.redAccent,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NET PAYABLE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                          Text(
                            '₹${(invoice['net'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: const BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final id = (invoice['id'] ?? invoice['invoiceNo'] ?? '001').toString();
                          final bytes = await ApiService.fetchInvoicePdf(id);
                          if (bytes != null && context.mounted) {
                            final summaryText = '''
🐄 *Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur* - Invoice Slip
Bill No: ${invoice['invoiceNo']}
Member: ${invoice['member']}
Cycle: ${invoice['cycle']}
Total Milk: ${invoice['milk']} Ltr
Gross Amount: ₹${invoice['gross']}
Advance Recovery: -₹${invoice['advance']}
Deductions: -₹${invoice['deduction']}
Net Farmer Payable: ₹${invoice['net']}
Status: ${invoice['status']}
''';
                            await PdfDownloadDialog.show(
                              context: context,
                              title: 'Invoice Slip',
                              fileName: 'SmartDairy_Invoice_${invoice['invoiceNo']}.pdf',
                              pdfBytes: bytes,
                              summaryText: summaryText,
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Download PDF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Invoice ${invoice['invoiceNo']} shared via WhatsApp.',
                              ),
                              backgroundColor: primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share Bill'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text(
                      'View Detailed Cycle Statement (तपशीलवार बिल)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DetailedBillStatementScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slipRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: secondaryText),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? darkText,
          ),
        ),
      ],
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: darkText,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ApiService.userRole.toUpperCase() == 'MEMBER'
                  ? 'My Invoices & Billing'.tr
                  : 'Invoices & Billing'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            Text(
              ApiService.userRole.toUpperCase() == 'MEMBER'
                  ? 'View your payment bills, deductions & cycle slips'.tr
                  : 'Generate and track farmer payment bills'.tr,
              style: const TextStyle(
                fontSize: 10,
                color: secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text(
              '10-Day Slip',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DetailedBillStatementScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: secondaryText,
          indicatorColor: primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Generate Invoice'),
            Tab(text: 'Invoice History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildHistoryTab(),
        ],
      ),
    );
      },
    );
  }

  // =============================================================
  // TAB 1: GENERATE INVOICE
  // =============================================================
  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Member Bill',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Calculate net payout after deducting farmer advances and cattle feed.',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
          const SizedBox(height: 20),
          if (members.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No farmers registered yet. Add a farmer first before generating invoices.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
                    ),
                  ),
                ],
              ),
            ),

          // Member
          _fieldLabel('Select Member'),
          const SizedBox(height: 7),
          _dropdownField(
            value: selectedMember,
            items: members,
            hintText: 'Select a farmer',
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedMember = value);
            },
          ),
          const SizedBox(height: 16),

          // Cycle
          _fieldLabel('Payment Cycle'),
          const SizedBox(height: 7),
          _dropdownField(
            value: selectedCycle,
            items: cycles,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedCycle = value);
            },
          ),
          const SizedBox(height: 16),

          // Milk Quantity
          _fieldLabel('Milk Quantity (Litres)'),
          const SizedBox(height: 7),
          _textField(
            controller: milkController,
            hint: 'Enter milk quantity',
            suffix: 'L',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Gross Amount
          _fieldLabel('Gross Milk Amount'),
          const SizedBox(height: 7),
          _textField(
            controller: grossController,
            hint: 'Enter gross amount',
            prefix: '₹ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Advance
          _fieldLabel('Advance Recovery Deduction'),
          const SizedBox(height: 7),
          _textField(
            controller: advanceController,
            hint: 'Enter advance deduction',
            prefix: '₹ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Other Deduction
          _fieldLabel('Cattle Feed / Other Deductions'),
          const SizedBox(height: 7),
          _textField(
            controller: deductionController,
            hint: 'Enter other deduction',
            prefix: '₹ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Net Payable Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB8E2DB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Farmer Payable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₹${netPayable.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _generateInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text(
                'GENERATE & PREVIEW SLIP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 2: INVOICE HISTORY
  // =============================================================
  Widget _buildHistoryTab() {
    if (_invoicesHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 36, color: primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Invoices Generated Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText),
              ),
              const SizedBox(height: 6),
              const Text(
                'Generate your first billing invoice for members using the Generate Invoice tab.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Generate Invoice', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _invoicesHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final inv = _invoicesHistory[index];
        final bool isPaid = inv['status'] == 'Paid';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E9E8)),
          ),
          child: InkWell(
            onTap: () => _showInvoiceSlipModal(inv),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv['member'].toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${inv['invoiceNo']} • ${inv['cycle']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFEAF7EC)
                            : const Color(0xFFFFF4DF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        inv['status'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPaid
                              ? const Color(0xFF3C9145)
                              : const Color(0xFFE58A00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _historyMiniItem('Milk', '${inv['milk']} L'),
                    _historyMiniItem('Gross', '₹${(inv['gross'] as double).toStringAsFixed(0)}'),
                    _historyMiniItem(
                      'Deductions',
                      '₹${((inv['advance'] as double) + (inv['deduction'] as double)).toStringAsFixed(0)}',
                      valueColor: Colors.redAccent,
                    ),
                    _historyMiniItem(
                      'Net Payout',
                      '₹${(inv['net'] as double).toStringAsFixed(0)}',
                      valueColor: primary,
                      isBold: true,
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

  Widget _historyMiniItem(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: secondaryText),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    );
  }

  Widget _dropdownField({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
  }) {
    final validValue = items.contains(value) ? value : null;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDDE2E7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          hint: hintText != null ? Text(hintText, style: const TextStyle(fontSize: 13, color: secondaryText)) : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: secondaryText,
          ),
          style: const TextStyle(fontSize: 13, color: darkText),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: secondaryText),
        prefixText: prefix,
        prefixStyle: const TextStyle(fontSize: 14, color: darkText),
        suffixText: suffix,
        suffixStyle: const TextStyle(fontSize: 13, color: secondaryText),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDDE2E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDDE2E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
    );
  }
}