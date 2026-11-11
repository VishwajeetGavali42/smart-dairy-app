import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';

class AddDispatchScreen extends StatefulWidget {
  const AddDispatchScreen({super.key});
  @override
  State<AddDispatchScreen> createState() => _AddDispatchScreenState();
}

class _AddDispatchScreenState extends State<AddDispatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destination = TextEditingController();
  final _quantity = TextEditingController();
  final _vehicle = TextEditingController();
  final _notes = TextEditingController();

  String _type = 'Cow Milk';
  String _status = 'Dispatched';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _destination.dispose();
    _quantity.dispose();
    _vehicle.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
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
      'destination': _destination.text.trim(),
      'type': _type,
      'quantity': double.parse(_quantity.text.trim()),
      'vehicle': _vehicle.text.trim(),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _DispatchColors.dark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Dispatch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _DispatchColors.dark)),
              Text('Record outgoing milk load', style: TextStyle(fontSize: 10, color: _DispatchColors.muted)),
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
                _label('Destination Plant (Letters only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _destination,
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                  decoration: _field('Plant or chilling center name (letters only)', Icons.location_on_outlined),
                  validator: (value) => ValidationUtils.validateName(value, fieldName: 'Destination Plant Name'),
                ),
                const SizedBox(height: 20),
                _label('Milk Type'),
                const SizedBox(height: 8),
                _dropdown(_type, const ['Cow Milk', 'Buffalo Milk', 'Mixed Milk'], (value) => setState(() => _type = value!)),
                const SizedBox(height: 20),
                _label('Quantity (Litres - Numbers only)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: ValidationUtils.decimalNumberFormatter,
                  decoration: _field('Enter milk quantity (numbers only)', Icons.local_drink_outlined),
                  validator: (value) => ValidationUtils.validateQuantity(value, fieldName: 'Dispatch Quantity'),
                ),
                const SizedBox(height: 20),
                _label('Vehicle / Tanker Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _vehicle,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _field('e.g. MH 12 AB 4567', Icons.directions_car_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter vehicle number' : null,
                ),
                const SizedBox(height: 20),
                _label('Dispatch Status'),
                const SizedBox(height: 8),
                _dropdown(_status, const ['Dispatched', 'In Transit', 'Delivered'], (value) => setState(() => _status = value!)),
                const SizedBox(height: 20),
                _label('Dispatch Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pick,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: _box(),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: _DispatchColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_date.day.toString().padLeft(2, '0')} ${_month(_date.month)} ${_date.year}',
                            style: const TextStyle(color: _DispatchColors.dark),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: _DispatchColors.muted)
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
                  decoration: _field('Add dispatch notes...', Icons.notes_rounded),
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
                backgroundColor: _DispatchColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Dispatch', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _DispatchColors.dark));

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> callback) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _box(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14, color: _DispatchColors.dark)))).toList(),
            onChanged: callback,
          ),
        ),
      );
}

BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE1E5EA)));
InputDecoration _field(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _DispatchColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _DispatchColors.primary)));
String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
class _DispatchColors {
  static const primary = Color(0xFF087F73);
  static const dark = Color(0xFF14213D);
  static const muted = Color(0xFF7A869A);
}
