import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';

class RateChartScreen extends StatefulWidget {
  const RateChartScreen({super.key});

  @override
  State<RateChartScreen> createState() => _RateChartScreenState();
}

class _RateChartScreenState extends State<RateChartScreen> {
  String _animal = 'Cow';

  // Configurable rate parameters
  double _cowBaseRate = 26.30;
  double _cowFatStep = 2.0;
  double _cowSnfStep = 5.0;

  double _buffaloBaseRate = 38.00;
  double _buffaloFatStep = 3.0;
  double _buffaloSnfStep = 5.0;

  List<double> get _fatValues => _animal == 'Cow'
      ? List<double>.generate(54, (index) => 2.7 + index / 10)
      : List<double>.generate(31, (index) => 5.0 + index / 10);

  List<double> get _snfValues => _animal == 'Cow'
      ? List<double>.generate(21, (index) => 7.7 + index / 10)
      : List<double>.generate(13, (index) => 8.5 + index / 10);

  double _rate(double fat, double snf) {
    if (_animal == 'Cow') {
      return _cowBaseRate + (fat - 2.7) * _cowFatStep + (snf - 7.7) * _cowSnfStep;
    }
    return _buffaloBaseRate + (fat - 5.0) * _buffaloFatStep + (snf - 8.5) * _buffaloSnfStep;
  }

  void _showEditRatesSheet() {
    final baseController = TextEditingController(
      text: (_animal == 'Cow' ? _cowBaseRate : _buffaloBaseRate).toStringAsFixed(2),
    );
    final fatStepController = TextEditingController(
      text: (_animal == 'Cow' ? _cowFatStep : _buffaloFatStep).toStringAsFixed(2),
    );
    final snfStepController = TextEditingController(
      text: (_animal == 'Cow' ? _cowSnfStep : _buffaloSnfStep).toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit $_animal Rate Rule',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _RateColors.dark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF3EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _animal == 'Cow' ? '🐄 Cow' : '🐃 Buffalo',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _RateColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Configure base purchase price and FAT/SNF slab increments.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                  ),
                  const SizedBox(height: 18),
                  _sheetInputField(
                    baseController,
                    'Base Purchase Rate (per Litre)',
                    'Base price at reference FAT/SNF',
                    prefix: '₹ ',
                  ),
                  const SizedBox(height: 14),
                  _sheetInputField(
                    fatStepController,
                    'FAT Increment (per 1.0 FAT above base)',
                    'Rate increase per full FAT percentage',
                    prefix: '₹ ',
                  ),
                  const SizedBox(height: 14),
                  _sheetInputField(
                    snfStepController,
                    'SNF Increment (per 1.0 SNF above base)',
                    'Rate increase per full SNF percentage',
                    prefix: '₹ ',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _RateColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final newBase = double.tryParse(baseController.text.trim());
                        final newFat = double.tryParse(fatStepController.text.trim());
                        final newSnf = double.tryParse(snfStepController.text.trim());

                        if (newBase != null && newFat != null && newSnf != null) {
                          setState(() {
                            if (_animal == 'Cow') {
                              _cowBaseRate = newBase;
                              _cowFatStep = newFat;
                              _cowSnfStep = newSnf;
                            } else {
                              _buffaloBaseRate = newBase;
                              _buffaloFatStep = newFat;
                              _buffaloSnfStep = newSnf;
                            }
                          });
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$_animal rate chart updated successfully.'),
                              backgroundColor: _RateColors.primary,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 19),
                      label: const Text(
                        'Apply & Recalculate Chart',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetInputField(
    TextEditingController controller,
    String label,
    String hint, {
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _RateColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: ValidationUtils.decimalNumberFormatter,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: const Color(0xFFF8FAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _RateColors.primary, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7FAF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF43A99F),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate Chart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                'Smart Dairy Price Matrix',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showEditRatesSheet,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Configure Rates',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _animalSelector(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_animal rate chart',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _RateColors.dark,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _showEditRatesSheet,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Edit Rules'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _RateColors.primary,
                              side: const BorderSide(color: _RateColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rate parameters summary banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F6F3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB8E2DB)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _paramTag('Base Rate', '₹${(_animal == 'Cow' ? _cowBaseRate : _buffaloBaseRate).toStringAsFixed(2)}'),
                            _paramTag('FAT Step', '+₹${(_animal == 'Cow' ? _cowFatStep : _buffaloFatStep).toStringAsFixed(1)}'),
                            _paramTag('SNF Step', '+₹${(_animal == 'Cow' ? _cowSnfStep : _buffaloSnfStep).toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _matrixTable(),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF2),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: const Color(0xFFF0E2BD)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFE09B19)),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Scroll horizontally to view all SNF values and vertically to view all FAT values. Milk collection calculates prices based on this matrix.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _paramTag(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF5A7184)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _RateColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _animalSelector() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _animalButton('Cow', '🐄')),
            const SizedBox(width: 10),
            Expanded(child: _animalButton('Buffalo', '🐃')),
          ],
        ),
      );

  Widget _animalButton(String animal, String emoji) {
    final selected = _animal == animal;
    return InkWell(
      onTap: () => setState(() => _animal = animal),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDF3EF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _RateColors.primary : const Color(0xFFE1E5EA),
          ),
        ),
        child: Center(
          child: Text(
            '$emoji  $animal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _RateColors.primary : _RateColors.dark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _matrixTable() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9DEDD)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(72),
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFD9DEDD)),
              verticalInside: BorderSide(color: Color(0xFFD9DEDD)),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF0F7F5)),
                children: [
                  _headerCell('FAT/SNF', width: 78),
                  ..._snfValues.map((snf) => _headerCell(snf.toStringAsFixed(1))),
                ],
              ),
              ..._fatValues.map(
                (fat) => TableRow(
                  children: [
                    _fatCell(fat.toStringAsFixed(1)),
                    ..._snfValues.map((snf) => _rateCell(_rate(fat, snf))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _headerCell(String text, {double? width}) => SizedBox(
        width: width,
        height: 44,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _RateColors.dark,
            ),
          ),
        ),
      );

  Widget _fatCell(String text) => SizedBox(
        height: 42,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _RateColors.dark,
            ),
          ),
        ),
      );

  Widget _rateCell(double rate) => SizedBox(
        height: 42,
        child: Center(
          child: Text(
            rate.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12, color: _RateColors.dark),
          ),
        ),
      );
}

class _RateColors {
  static const primary = Color(0xFF087F73);
  static const dark = Color(0xFF14213D);
}
