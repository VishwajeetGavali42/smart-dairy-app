import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';

import 'add_deduction_screen.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class DeductionScreen extends StatefulWidget {
  const DeductionScreen({super.key});

  @override
  State<DeductionScreen> createState() => _DeductionScreenState();
}

class _DeductionScreenState extends State<DeductionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  final List<Map<String, dynamic>> _deductions = [];

  @override
  void initState() {
    super.initState();
    _loadDeductions();
  }

  Future<void> _loadDeductions() async {
    try {
      final data = await ApiService.getDeductions();
      if (mounted) {
        setState(() {
          _deductions.clear();
          for (final item in data) {
            _deductions.add({
              'id': item['id'],
              'member': item['memberName'] ?? item['member'] ?? 'Member',
              'animal': item['animal'] ?? 'Cow',
              'type': item['deductionType'] ?? item['reason'] ?? item['type'] ?? 'General',
              'amount': (item['amount'] as num?)?.toDouble() ?? 0.0,
              'date': item['date'] ?? 'Today',
              'recurring': item['recurring'] ?? false,
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDeductions {
    final query = _searchController.text.toLowerCase().trim();
    return _deductions.where((deduction) {
      final matchesQuery = deduction['member'].toString().toLowerCase().contains(query) || deduction['type'].toString().toLowerCase().contains(query);
      final matchesFilter = _filter == 'All' || (_filter == 'Recurring' ? deduction['recurring'] == true : deduction['recurring'] == false);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _openAddDeduction() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddDeductionScreen()),
    );
    if (result != null && mounted) {
      setState(() => _deductions.insert(0, result));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deduction saved successfully')));

      final payload = {
        'memberCode': 'M001',
        'memberName': result['member'],
        'deductionType': result['type'],
        'amount': result['amount'],
        'date': result['date'],
        'recurring': result['recurring'] ?? false,
      };

      ApiService.createDeduction(payload).then((res) {
        if (res == null) SyncService.enqueue('deduction', payload);
      }).catchError((_) {
        SyncService.enqueue('deduction', payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _deductions.fold<double>(0, (sum, item) => sum + item['amount']);
    final recurring = _deductions.where((item) => item['recurring'] == true).fold<double>(0, (sum, item) => sum + item['amount']);
    final filtered = _filteredDeductions;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _Colors.dark), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Deductions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _Colors.dark)),
          Text('Manage member deductions', style: TextStyle(fontSize: 10, color: _Colors.muted)),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Deduction Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Colors.dark)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _summaryCard(Icons.remove_circle_outline_rounded, 'Total deductions', '₹${total.toStringAsFixed(0)}', _Colors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard(Icons.repeat_rounded, 'Recurring', '₹${recurring.toStringAsFixed(0)}', const Color(0xFFFF9800))),
            ]),
            const SizedBox(height: 24),
            const Text('Member Deductions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Colors.dark)),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('Search member or deduction type', Icons.search_rounded),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: ['All', 'Recurring', 'One-time'].map((item) => ChoiceChip(
              label: Text(item), selected: _filter == item,
              onSelected: (_) => setState(() => _filter = item),
              selectedColor: _Colors.primary, backgroundColor: Colors.white,
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _filter == item ? Colors.white : _Colors.muted),
              shape: StadiumBorder(side: BorderSide(color: _filter == item ? _Colors.primary : const Color(0xFFE1E5EA))),
            )).toList()),
            const SizedBox(height: 14),
            if (filtered.isEmpty) _emptyState() else ...filtered.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _deductionCard(item))),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDeduction, backgroundColor: _Colors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded), label: const Text('Add Deduction', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _summaryCard(IconData icon, String title, String value, Color color) => Container(
    padding: const EdgeInsets.all(13), decoration: _cardDecoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 19, color: color)),
      const SizedBox(height: 9), Text(title, style: const TextStyle(fontSize: 10, color: _Colors.muted)), const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _Colors.dark)),
    ]),
  );

  Widget _deductionCard(Map<String, dynamic> item) {
    final bool recurring = item['recurring'] == true;
    return Container(padding: const EdgeInsets.all(13), decoration: _cardDecoration(), child: Column(children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: const BoxDecoration(color: Color(0xFFE7F6F3), shape: BoxShape.circle), child: Icon(item['animal'] == 'Cow' ? Icons.agriculture_outlined : Icons.agriculture, color: _Colors.primary, size: 21)),
        const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['member'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Colors.dark)),
          const SizedBox(height: 2), Text('${item['animal']} • ${item['type']}', style: const TextStyle(fontSize: 10, color: _Colors.muted)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: recurring ? const Color(0xFFFFF3E0) : const Color(0xFFEAF7EC), borderRadius: BorderRadius.circular(12)), child: Text(recurring ? 'Recurring' : 'One-time', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: recurring ? const Color(0xFFF57C00) : const Color(0xFF399342)))),
      ]),
      const Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Divider(height: 1, color: Color(0xFFEDF0F2))),
      Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF98A2B3)), const SizedBox(width: 5), Text(item['date'], style: const TextStyle(fontSize: 10, color: _Colors.muted)), const Spacer(),
        Text('₹${item['amount'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Colors.primary)),
        IconButton(icon: const Icon(Icons.more_vert_rounded, size: 20, color: _Colors.muted), onPressed: () => _showActions(item)),
      ]),
    ]));
  }

  void _showActions(Map<String, dynamic> item) => showModalBottomSheet<void>(context: context, builder: (sheetContext) => SafeArea(child: Wrap(children: [
    ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit deduction'), onTap: () {
      Navigator.pop(sheetContext);
      _showEditDeductionDialog(item);
    }),
    ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Delete deduction', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(sheetContext); setState(() => _deductions.remove(item)); }),
  ])));

  void _showEditDeductionDialog(Map<String, dynamic> item) {
    final amountController = TextEditingController(text: (item['amount'] as double).toStringAsFixed(0));
    String selectedType = item['type'];
    bool isRecurring = item['recurring'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Deduction — ${item['member']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Colors.dark)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: _inputDecoration('Type', Icons.category_outlined),
                items: const ['Cattle Feed', 'Advance Recovery', 'Insurance', 'Equipment', 'Loan', 'Other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) { if (v != null) setSheetState(() => selectedType = v); },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: ValidationUtils.decimalNumberFormatter,
                decoration: _inputDecoration('Amount (₹)', Icons.currency_rupee_rounded),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring Deduction', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _Colors.dark)),
                subtitle: const Text('Apply in every cycle', style: TextStyle(fontSize: 11, color: _Colors.muted)),
                value: isRecurring,
                activeThumbColor: _Colors.primary,
                onChanged: (v) => setSheetState(() => isRecurring = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _Colors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    final newAmount = double.tryParse(amountController.text.trim());
                    if (newAmount == null || newAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                      return;
                    }
                    setState(() {
                      item['type'] = selectedType;
                      item['amount'] = newAmount;
                      item['recurring'] = isRecurring;
                    });
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deduction updated successfully'), backgroundColor: _Colors.primary));
                  },
                  child: const Text('UPDATE DEDUCTION', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _Colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.percent_rounded, size: 36, color: _Colors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No Deductions Recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _Colors.dark)),
          const SizedBox(height: 6),
          const Text('Track cattle feed, advance recovery, or loan deductions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _Colors.muted)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _openAddDeduction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add First Deduction', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _Colors.primary), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _Colors.primary)));
BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E5EA)));
class _Colors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
