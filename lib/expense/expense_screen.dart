import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';

import 'add_expense_screen.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/sync_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  final List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await ApiService.getExpenses();
      if (mounted) {
        setState(() {
          _expenses.clear();
          for (final item in data) {
            _expenses.add({
              'id': item['id'],
              'title': item['title'] ?? item['category'] ?? 'Dairy Expense',
              'category': item['category'] ?? 'Feed',
              'amount': (item['amount'] as num?)?.toDouble() ?? 0.0,
              'date': item['date'] ?? 'Today',
              'method': item['paymentMode'] ?? 'Cash',
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _visibleExpenses {
    final query = _searchController.text.trim().toLowerCase();
    return _expenses.where((item) => (_filter == 'All' || item['category'] == _filter) && (query.isEmpty || item['title'].toString().toLowerCase().contains(query) || item['category'].toString().toLowerCase().contains(query))).toList();
  }

  Future<void> _addExpense() async {
    final expense = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
    if (expense != null && mounted) {
      setState(() => _expenses.insert(0, expense));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense saved successfully')));

      final payload = {
        'title': expense['title'],
        'category': expense['category'],
        'amount': expense['amount'],
        'date': expense['date'],
        'paymentMode': expense['method'],
      };

      ApiService.createExpense(payload).then((res) {
        if (res == null) SyncService.enqueue('expense', payload);
      }).catchError((_) {
        SyncService.enqueue('expense', payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        final total = _expenses.fold<double>(0, (sum, item) => sum + item['amount']);
        final feed = _expenses.where((item) => item['category'] == 'Feed').fold<double>(0, (sum, item) => sum + item['amount']);
        final expenses = _visibleExpenses;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _ExpenseColors.dark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expense'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
                const Text('Track dairy operating costs', style: TextStyle(fontSize: 10, color: _ExpenseColors.muted)),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Expenses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _summary(Icons.account_balance_wallet_outlined, 'Total Expense', '₹${total.toStringAsFixed(0)}', _ExpenseColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _summary(Icons.agriculture_outlined, 'Feed Expense', '₹${feed.toStringAsFixed(0)}', const Color(0xFFF57C00))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Expense History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
                  const SizedBox(height: 10),
                  TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: _input('Search expense...', Icons.search_rounded)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Feed', 'Utilities', 'Transport', 'Maintenance'].map((item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item),
                          selected: _filter == item,
                          onSelected: (_) => setState(() => _filter = item),
                          selectedColor: _ExpenseColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _filter == item ? Colors.white : _ExpenseColors.muted),
                          shape: StadiumBorder(side: BorderSide(color: _filter == item ? _ExpenseColors.primary : const Color(0xFFE1E5EA))),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (expenses.isEmpty) _empty() else ...expenses.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _expenseCard(item))),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addExpense,
            backgroundColor: _ExpenseColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _summary(IconData icon, String label, String value, Color color) => Container(padding: const EdgeInsets.all(13), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 19)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 10, color: _ExpenseColors.muted)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ExpenseColors.dark))]));
  Widget _expenseCard(Map<String, dynamic> item) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _card(),
    child: Row(children: [
      Container(width: 43, height: 43, decoration: BoxDecoration(color: _categoryColor(item['category']).withValues(alpha: .11), borderRadius: BorderRadius.circular(12)), child: Icon(_categoryIcon(item['category']), color: _categoryColor(item['category']), size: 21)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
        const SizedBox(height: 3),
        Text('${item['category']} • ${item['date']} • ${item['method']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _ExpenseColors.muted)),
      ])),
      const SizedBox(width: 8),
      Text('₹${item['amount'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ExpenseColors.primary)),
      IconButton(
        icon: const Icon(Icons.more_vert_rounded, size: 20, color: _ExpenseColors.muted),
        onPressed: () => _showExpenseOptions(item),
      ),
    ]),
  );

  void _showExpenseOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _ExpenseColors.primary),
              title: const Text('Edit Expense'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditExpenseDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Expense', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _expenses.remove(item));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditExpenseDialog(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title']);
    final amountCtrl = TextEditingController(text: (item['amount'] as double).toStringAsFixed(0));
    String selectedCat = item['category'];

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
              const Text('Edit Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                inputFormatters: ValidationUtils.lettersOnlyFormatter,
                decoration: _input('Expense Title', Icons.title_rounded),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: _input('Category', Icons.category_outlined),
                items: const ['Feed', 'Utilities', 'Transport', 'Maintenance', 'Medical', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setSheetState(() => selectedCat = v); },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: ValidationUtils.decimalNumberFormatter,
                decoration: _input('Amount (₹)', Icons.currency_rupee_rounded),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ExpenseColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.trim());
                    if (title.isEmpty || amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid details')));
                      return;
                    }
                    setState(() {
                      item['title'] = title;
                      item['category'] = selectedCat;
                      item['amount'] = amt;
                    });
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense updated successfully'), backgroundColor: _ExpenseColors.primary));
                  },
                  child: const Text('UPDATE EXPENSE', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Color _categoryColor(String category) => switch (category) {'Feed' => const Color(0xFFF57C00), 'Utilities' => const Color(0xFF4B8EF7), 'Transport' => const Color(0xFF8E63CE), _ => _ExpenseColors.primary};
  IconData _categoryIcon(String category) => switch (category) {'Feed' => Icons.agriculture_outlined, 'Utilities' => Icons.bolt_outlined, 'Transport' => Icons.local_shipping_outlined, _ => Icons.build_outlined};
  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _ExpenseColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: _ExpenseColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No Expenses Recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
          const SizedBox(height: 6),
          const Text('Track daily operations, feed purchase, fuel, and utility bills.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _ExpenseColors.muted)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _addExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ExpenseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add First Expense', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _input(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _ExpenseColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _ExpenseColors.primary)));
BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E5EA)));
class _ExpenseColors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
