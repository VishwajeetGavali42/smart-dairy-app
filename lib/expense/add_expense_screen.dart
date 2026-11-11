import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  String _category = 'Feed';
  String _method = 'Cash';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'title': _title.text.trim(),
      'category': _category,
      'amount': double.parse(_amount.text.trim()),
      'date': '${_date.day.toString().padLeft(2, '0')} ${_month(_date.month)} ${_date.year}',
      'method': _method,
      'notes': _notes.text.trim()
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _ExpenseColors.dark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ExpenseColors.dark)),
              Text('Record a dairy expense', style: TextStyle(fontSize: 10, color: _ExpenseColors.muted)),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Expense Title (Characters only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _title,
                  keyboardType: TextInputType.text,
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                  decoration: _field('e.g. Cattle feed purchase (letters only)', Icons.description_outlined),
                  validator: (value) => ValidationUtils.validateName(value, fieldName: 'Expense Title'),
                ),
                const SizedBox(height: 20),
                _label('Expense Category'),
                const SizedBox(height: 8),
                _dropdown(_category, const ['Feed', 'Utilities', 'Transport', 'Maintenance', 'Salary', 'Other'], (value) => setState(() => _category = value!)),
                const SizedBox(height: 20),
                _label('Amount (₹ - Numbers only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: ValidationUtils.decimalNumberFormatter,
                  decoration: _field('Enter expense amount (numbers only)', Icons.currency_rupee_rounded),
                  validator: (value) => ValidationUtils.validateAmount(value, fieldName: 'Expense Amount'),
                ),
                const SizedBox(height: 20),
                _label('Payment Method'),
                const SizedBox(height: 8),
                _dropdown(_method, const ['Cash', 'UPI', 'Bank Transfer', 'Online'], (value) => setState(() => _method = value!)),
                const SizedBox(height: 20),
                _label('Expense Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: _box(),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: _ExpenseColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_date.day.toString().padLeft(2, '0')} ${_month(_date.month)} ${_date.year}',
                            style: const TextStyle(color: _ExpenseColors.dark),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: _ExpenseColors.muted)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _label('Notes (Optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: _field('Add expense notes...', Icons.notes_rounded),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ExpenseColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );

  Widget _label(String label) => Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ExpenseColors.dark));

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _box(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14, color: _ExpenseColors.dark)))).toList(),
            onChanged: onChanged,
          ),
        ),
      );
}

BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE1E5EA)));
InputDecoration _field(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _ExpenseColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _ExpenseColors.primary)));
String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
class _ExpenseColors {
  static const primary = Color(0xFF087F73);
  static const dark = Color(0xFF14213D);
  static const muted = Color(0xFF7A869A);
}
