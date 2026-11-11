import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';

class AddMilkSaleScreen extends StatefulWidget {
  const AddMilkSaleScreen({super.key});
  @override
  State<AddMilkSaleScreen> createState() => _AddMilkSaleScreenState();
}

class _AddMilkSaleScreenState extends State<AddMilkSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buyer = TextEditingController();
  final _quantity = TextEditingController();
  final _rate = TextEditingController();
  final _notes = TextEditingController();

  String _milk = 'Cow Milk';
  String _status = 'Paid';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _buyer.dispose();
    _quantity.dispose();
    _rate.dispose();
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
      'buyer': _buyer.text.trim(),
      'milk': _milk,
      'quantity': double.parse(_quantity.text.trim()),
      'rate': double.parse(_rate.text.trim()),
      'date': '${_date.day.toString().padLeft(2, '0')} ${_month(_date.month)} ${_date.year}',
      'status': _status,
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _SaleColors.dark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Milk Sale', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _SaleColors.dark)),
              Text('Record outgoing milk sale', style: TextStyle(fontSize: 10, color: _SaleColors.muted)),
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
                _label('Buyer / Customer Name (Characters only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _buyer,
                  keyboardType: TextInputType.name,
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                  decoration: _field('Enter buyer name (letters only)', Icons.storefront_outlined),
                  validator: (value) => ValidationUtils.validateName(value, fieldName: 'Buyer Name'),
                ),
                const SizedBox(height: 20),
                _label('Milk Type'),
                const SizedBox(height: 8),
                _dropdown(_milk, const ['Cow Milk', 'Buffalo Milk', 'Mixed Milk'], (value) => setState(() => _milk = value!)),
                const SizedBox(height: 20),
                _label('Quantity (Litres - Numbers only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: ValidationUtils.decimalNumberFormatter,
                  decoration: _field('Enter milk quantity (e.g. 1.5)', Icons.local_drink_outlined),
                  validator: (value) => ValidationUtils.validateQuantity(value, fieldName: 'Milk Quantity'),
                ),
                const SizedBox(height: 20),
                _label('Rate per Litre (₹ - Numbers only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: ValidationUtils.decimalNumberFormatter,
                  decoration: _field('Enter sale rate (e.g. 52.0)', Icons.currency_rupee_rounded),
                  validator: (value) => ValidationUtils.validateAmount(value, fieldName: 'Rate per Litre'),
                ),
                const SizedBox(height: 20),
                _label('Payment Status'),
                const SizedBox(height: 8),
                _dropdown(_status, const ['Paid', 'Pending'], (value) => setState(() => _status = value!)),
                const SizedBox(height: 20),
                _label('Sale Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: _box(),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: _SaleColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_date.day.toString().padLeft(2, '0')} ${_month(_date.month)} ${_date.year}',
                            style: const TextStyle(color: _SaleColors.dark),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: _SaleColors.muted)
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
                  decoration: _field('Add sale notes...', Icons.notes_rounded),
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
                backgroundColor: _SaleColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Milk Sale', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );

  Widget _label(String label) => Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _SaleColors.dark));

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _box(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14, color: _SaleColors.dark)))).toList(),
            onChanged: onChanged,
          ),
        ),
      );
}

BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE1E5EA)));
InputDecoration _field(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _SaleColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _SaleColors.primary)));
String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
class _SaleColors {
  static const primary = Color(0xFF087F73);
  static const dark = Color(0xFF14213D);
  static const muted = Color(0xFF7A869A);
}
