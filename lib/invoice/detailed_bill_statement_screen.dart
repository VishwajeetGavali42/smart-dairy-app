import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/pdf_download_dialog.dart';
import '../screens/ai_chat_screen.dart';

class DetailedBillStatementScreen extends StatefulWidget {
  final String? initialMemberCode;

  const DetailedBillStatementScreen({super.key, this.initialMemberCode});

  @override
  State<DetailedBillStatementScreen> createState() =>
      _DetailedBillStatementScreenState();
}

class _DetailedBillStatementScreenState
    extends State<DetailedBillStatementScreen> {
  bool _isLoading = true;
  String _selectedMemberCode = 'M001';
  int _selectedCycle = 1; // 1: Days 1-10, 2: Days 11-20, 3: Days 21-End
  Map<String, dynamic>? _statementData;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMemberCode != null &&
        widget.initialMemberCode!.isNotEmpty) {
      _selectedMemberCode = widget.initialMemberCode!;
    } else if (ApiService.userRole.toUpperCase() == 'MEMBER') {
      _selectedMemberCode = ApiService.currentMemberCode ?? 'M001';
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final membersList = await ApiService.getMembers();
      _members = membersList
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      final availableCodes = _members
          .map((m) => (m['memberCode'] ?? m['id'] ?? m['code'])?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList();

      if (!availableCodes.contains(_selectedMemberCode) && availableCodes.isNotEmpty) {
        _selectedMemberCode = availableCodes.first;
      }
      await _fetchStatement();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStatement() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getDetailedCycleStatementData(
        _selectedMemberCode,
        cycle: _selectedCycle,
      );
      setState(() {
        _statementData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statement: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openPdf() async {
    if (_statementData == null) return;
    final pdfBytes = await ApiService.fetchDetailedStatementPdf(
      _selectedMemberCode,
    );
    if (pdfBytes != null && mounted) {
      final member = _statementData!['memberInfo'] ?? {};
      final summary = _statementData!['summary'] ?? {};
      final summaryText =
          '''
🐄 *Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur* - 10-Day Billing Slip
👤 Member: $_selectedMemberCode - ${member['name'] ?? ''}
📅 Period: ${_statementData!['cyclePeriod']}
🥛 Total Milk: ${summary['totalLiters']} Ltr
💰 Net Payable: ₹${summary['netPayable']}
Bank: ${member['bankName'] ?? ''} (${member['accountNo'] ?? ''})
''';
      await PdfDownloadDialog.show(
        context: context,
        title: 'Detailed Cycle Statement',
        fileName: 'SmartDairy_Statement_$_selectedMemberCode.pdf',
        pdfBytes: pdfBytes,
        summaryText: summaryText,
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    if (_statementData == null) return;
    final pdfBytes = await ApiService.fetchDetailedStatementPdf(
      _selectedMemberCode,
    );
    final member = _statementData!['memberInfo'] ?? {};
    final summary = _statementData!['summary'] ?? {};
    final summaryText = '''
🐄 *Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur* - 10-Day Billing Slip
👤 Member: $_selectedMemberCode - ${member['name'] ?? ''}
📅 Period: ${_statementData!['cyclePeriod']}
🥛 Total Milk: ${summary['totalLiters']} Ltr
💰 Net Payable: ₹${summary['netPayable']}
Bank: ${member['bankName'] ?? ''} (${member['accountNo'] ?? ''})
''';
    if (pdfBytes != null) {
      await PdfGeneratorService.sharePdf(
        fileName: 'SmartDairy_Statement_$_selectedMemberCode.pdf',
        pdfBytes: pdfBytes,
        summaryText: summaryText,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Billing Statement shared for ${member['name'] ?? _selectedMemberCode}',
          ),
          backgroundColor: const Color(0xFF25D366),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Cycle Statement',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '१० दिवसीय तपशीलवार दूध बिल पत्रक',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ask AI Assistant',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AiChatScreen(initialScreenContext: 'billing'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Print / Download PDF',
            icon: const Icon(Icons.print_outlined),
            onPressed: _openPdf,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStatement,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statementData == null
          ? const Center(child: Text('No statement data available'))
          : RefreshIndicator(
              onRefresh: _fetchStatement,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMemberSelector(colorScheme),
                    const SizedBox(height: 12),
                    _buildBillContainer(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildActionRow(colorScheme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMemberSelector(ColorScheme colorScheme) {
    final bool isMember = ApiService.userRole.toUpperCase() == 'MEMBER';

    final availableCodes = _members
        .map((m) => (m['memberCode'] ?? m['id'] ?? m['code'])?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    if (availableCodes.isEmpty) {
      availableCodes.addAll(['M001', 'M002', 'M003', 'M004', 'M005']);
    }

    final currentValue = availableCodes.contains(_selectedMemberCode)
        ? _selectedMemberCode
        : (availableCodes.first);

    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person_pin, color: Color(0xFF087F73)),
                const SizedBox(width: 10),
                Text(
                  isMember ? 'Member:' : 'Select Member:',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isMember
                      ? Text(
                          '$_selectedMemberCode - ${ApiService.currentMemberName ?? "Ramesh Patil"}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: currentValue,
                            items: availableCodes.map((code) {
                              final memberObj = _members.firstWhere(
                                (m) =>
                                    (m['memberCode'] ?? m['id'] ?? m['code'])
                                        ?.toString() ==
                                    code,
                                orElse: () => <String, dynamic>{},
                              );
                              final name = memberObj['name'] ??
                                  memberObj['farmerName'] ??
                                  (code == 'M001'
                                      ? 'Ramesh Patil'
                                      : (code == 'M002'
                                          ? 'Suresh Deshmukh'
                                          : (code == 'M003'
                                              ? 'Anand Shinde'
                                              : (code == 'M004'
                                                  ? 'Prakash Jadhav'
                                                  : 'Sunita Kadam'))));
                              final animal = memberObj['animalType'] ?? (code == 'M004' ? 'Buffalo' : 'Cow');
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(
                                  '$code - $name ($animal)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null && val != _selectedMemberCode) {
                                setState(() {
                                  _selectedMemberCode = val;
                                });
                                _fetchStatement();
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 10-Day Billing Cycle Selector Chips
        Row(
          children: [
            Expanded(
              child: _cycleChip(1, 'Cycle 1 (1–10)'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _cycleChip(2, 'Cycle 2 (11–20)'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _cycleChip(3, 'Cycle 3 (21–End)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cycleChip(int cycle, String label) {
    final isSelected = _selectedCycle == cycle;
    return InkWell(
      onTap: () {
        if (_selectedCycle != cycle) {
          setState(() {
            _selectedCycle = cycle;
          });
          _fetchStatement();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF087F73) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF087F73) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillContainer(ThemeData theme, ColorScheme colorScheme) {
    final dairy = (_statementData!['dairyInfo'] as Map<String, dynamic>?) ?? {};
    final member = (_statementData!['memberInfo'] as Map<String, dynamic>?) ?? {};
    final summary = (_statementData!['summary'] as Map<String, dynamic>?) ?? {};
    final shiftRows = (_statementData!['dailyRows'] as List<dynamic>?) ?? [];
    final feedPurchases =
        (_statementData!['feedPurchases'] as List<dynamic>?) ?? (_statementData!['feedItems'] as List<dynamic>?) ?? [];
    final deductions = (_statementData!['deductions'] as List<dynamic>?) ?? [];

    final String memberCodeDisplay = (member['code'] ?? _statementData!['memberCode'] ?? _selectedMemberCode).toString();
    final String memberNameDisplay = (member['name'] ?? _statementData!['memberName'] ?? 'Member').toString();
    final String milkTypeDisplay = (member['milkType'] ?? _statementData!['milkType'] ?? 'COW').toString().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
            ),
            child: Column(
              children: [
                Text(
                  dairy['name'] ?? _statementData!['dairyName'] ?? 'Late L D Kadam Milk Producers Cooperative Society Ltd.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  '${dairy['address'] ?? _statementData!['centerLocation'] ?? 'Kadamwadi, Kolhapur'} | Phone: ${dairy['phone'] ?? _statementData!['centerPhone'] ?? '+91 98220 12345'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bill No: ${_statementData!['billNo'] ?? '721'}   |   Cycle: ${_statementData!['cyclePeriod'] ?? _statementData!['dateRange'] ?? '01/05/2026 To 10/05/2026'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Member Info Card inside statement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'सभासद: $memberCodeDisplay - $memberNameDisplay',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'गाव / शाखा: ${member['village'] ?? _statementData!['centerLocation'] ?? 'Kadamwadi'}   |   मो: ${member['phone'] ?? _statementData!['centerPhone'] ?? '9876543210'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
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
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Text(
                    'Type: $milkTypeDisplay',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Title: Daily Morning & Evening Collections Table
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(
              children: [
                Icon(Icons.table_chart, size: 16, color: Colors.blueGrey),
                SizedBox(width: 6),
                Text(
                  'दूध संकलन तपशील (Morning & Evening Shift)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Shift collection table horizontally scrollable for small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 36,
              columnSpacing: 10,
              horizontalMargin: 8,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFEEF2F6),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'तारीख\nDate',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'सकाळ\nLtr',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'FAT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SNF',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'दर ₹',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'सकाळ ₹',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'संध्या\nLtr',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'FAT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SNF',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'दर ₹',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'संध्या ₹',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'एकूण लिटर',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'एकूण रक्कम',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
              rows: shiftRows.map((r) {
                final m = r['m'] ?? {};
                final e = r['e'] ?? {};
                final totalLtr =
                    ((m['ltr'] ?? 0.0) as num) + ((e['ltr'] ?? 0.0) as num);
                final totalAmt =
                    ((m['amt'] ?? 0.0) as num) + ((e['amt'] ?? 0.0) as num);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        r['date']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['ltr'] != null ? '${m['ltr']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['fat'] != null ? '${m['fat']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['snf'] != null ? '${m['snf']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['rate'] != null ? '${m['rate']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['amt'] != null ? '${m['amt']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        e['ltr'] != null ? '${e['ltr']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        e['fat'] != null ? '${e['fat']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        e['snf'] != null ? '${e['snf']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        e['rate'] != null ? '${e['rate']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        e['amt'] != null ? '${e['amt']}' : '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        totalLtr.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${totalAmt.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Total Milk row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'एकूण दूध संकलन (10 दिवस):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${summary['totalLiters'] ?? _statementData!['totalQty'] ?? '0.0'} Ltr  |  ₹${summary['milkTotalAmount'] ?? _statementData!['totalMilkAmt'] ?? '0.00'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Cattle Feed & Supplies (पशूखाद्य) Section
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 6),
                Text(
                  'पशूखाद्य / औषधे खरेदी तपशील (Feed & Supplies Issued)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          feedPurchases.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'या बिलात कोणतीही पशूखाद्य खरेदी नाही (No feed purchases).',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 34,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 32,
                    columnSpacing: 18,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'तारीख',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'खाद्य प्रकार / वस्तू नाव',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'नग / पोती',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'दर ₹',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'एकूण रक्कम ₹',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    rows: feedPurchases.map((f) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              f['date']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              f['item']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${f['qty']}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹${f['rate']}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹${f['total']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

          const Divider(height: 1),

          // Deductions & Balance Ledger
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 6),
                Text(
                  'कपाती व हिशोब (Deductions & Adjustments)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...deductions.map((d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${d['name']}:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '- ₹${d['amount']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'एकूण कपात (Total Deductions):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '- ₹${summary['totalDeduction']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Net Settlement Banner (Matching Image)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: Colors.green.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'मागील बाकी (Previous Balance):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '₹${summary['previousBalance']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'दूध रक्कम (Milk Total):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '+ ₹${summary['milkTotalAmount']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'एकूण कपात (Deductions):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '- ₹${summary['totalDeduction']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'निव्वळ देय रक्कम (NET PAYABLE)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        Text(
                          'बँक खात्यात जमा केली जाईल',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                    Text(
                      '₹${summary['netPayable'] ?? _statementData!['netPayable'] ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'बँक: ${member['bankName'] ?? 'SBI'} | A/C: ${member['accountNo'] ?? '****1234'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'येणे बाकी: ₹${summary['remainingBalance'] ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text(
              'Save PDF',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _openPdf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.share, size: 20),
            label: const Text(
              'WhatsApp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _shareViaWhatsApp,
          ),
        ),
      ],
    );
  }
}
