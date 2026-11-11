import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';
import '../services/api_service.dart';

class AddDeductionScreen extends StatefulWidget {
  const AddDeductionScreen({super.key});
  @override
  State<AddDeductionScreen> createState() => _AddDeductionScreenState();
}

class _AddDeductionScreenState extends State<AddDeductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  List<Map<String, String>> _members = [];
  bool _isLoadingMembers = true;
  String? _member;
  String _type = 'Cattle Feed';
  bool _recurring = false;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final data = await ApiService.getMembers();
      if (mounted) {
        setState(() {
          _members = data.map<Map<String, String>>((m) => {
            'name': (m['name'] ?? m['farmerName'] ?? '').toString(),
            'animal': (m['animalType'] ?? m['animal'] ?? 'Cow').toString(),
          }).where((m) => m['name']!.isNotEmpty).toList();
          if (_members.isNotEmpty) {
            _member = _members.first['name'];
          }
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  @override
  void dispose() { _amountController.dispose(); _reasonController.dispose(); super.dispose(); }

  Future<void> _pickDate() async { final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) setState(() => _date = picked); }
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_member == null || _members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please register a farmer first before adding deductions.')));
      return;
    }
    final memberData = _members.firstWhere((item) => item['name'] == _member, orElse: () => {'name': _member!, 'animal': 'Cow'});
    Navigator.pop(context, {'member': _member, 'animal': memberData['animal'], 'type': _type, 'amount': double.parse(_amountController.text.trim()), 'date': '${_date.day.toString().padLeft(2, '0')} ${_monthName(_date.month)} ${_date.year}', 'recurring': _recurring, 'reason': _reasonController.text.trim()});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFA),
    appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _Colors.dark), onPressed: () => Navigator.pop(context)), title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add Deduction', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _Colors.dark)), Text('Record a member deduction', style: TextStyle(fontSize: 10, color: _Colors.muted))])),
    body: Form(key: _formKey, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Select Member'),
      const SizedBox(height: 8),
      if (_isLoadingMembers)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
      else if (_members.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFFFEEBA))),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('No farmers registered yet. Please add a farmer first.', style: TextStyle(fontSize: 13, color: Color(0xFF856404)))),
            ],
          ),
        )
      else
        _dropdown(_member!, _members.map((e) => e['name']!).toList(), (value) => setState(() => _member = value!)),
      const SizedBox(height: 20), _label('Deduction Type'), const SizedBox(height: 8), _dropdown(_type, const ['Loan', 'Feed', 'Cattle Feed', 'Insurance', 'Equipment', 'Advance Recovery', 'Other'], (value) => setState(() => _type = value!)),
      const SizedBox(height: 20), _label('Amount'), const SizedBox(height: 8), TextFormField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: ValidationUtils.decimalNumberFormatter, decoration: _fieldDecoration('Enter deduction amount', Icons.currency_rupee_rounded), validator: (value) { final amount = double.tryParse(value?.trim() ?? ''); return amount == null || amount <= 0 ? 'Enter a valid amount' : null; }),
      const SizedBox(height: 20), _label('Deduction Date'), const SizedBox(height: 8), InkWell(onTap: _pickDate, borderRadius: BorderRadius.circular(13), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15), decoration: _boxDecoration(), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 20, color: _Colors.primary), const SizedBox(width: 12), Expanded(child: Text('${_date.day.toString().padLeft(2, '0')} ${_monthName(_date.month)} ${_date.year}', style: const TextStyle(fontSize: 14, color: _Colors.dark))), const Icon(Icons.keyboard_arrow_down_rounded, color: _Colors.muted)]))),
      const SizedBox(height: 20), _label('Reason (Optional)'), const SizedBox(height: 8), TextFormField(controller: _reasonController, maxLines: 3, decoration: _fieldDecoration('Add reason or notes...', Icons.notes_rounded)),
      const SizedBox(height: 20), Container(padding: const EdgeInsets.all(14), decoration: _boxDecoration(), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.repeat_rounded, color: Color(0xFFF57C00))), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Recurring deduction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Colors.dark)), SizedBox(height: 3), Text('Apply this deduction in every payment cycle.', style: TextStyle(fontSize: 10, color: _Colors.muted))])), Switch(value: _recurring, activeThumbColor: _Colors.primary, onChanged: (value) => setState(() => _recurring = value))])),
    ]))),
    bottomNavigationBar: SafeArea(minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: SizedBox(height: 52, child: ElevatedButton.icon(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: _Colors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.check_rounded), label: const Text('Save Deduction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))))),
  );

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Colors.dark));
  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: _boxDecoration(), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _Colors.muted), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14, color: _Colors.dark)))).toList(), onChanged: onChanged)));
}

BoxDecoration _boxDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE1E5EA)));
InputDecoration _fieldDecoration(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _Colors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _Colors.primary)));
String _monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
class _Colors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
