import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';
import '../services/api_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSave;

  const AddPaymentScreen({
    super.key,
    this.onSave,
  });

  @override
  State<AddPaymentScreen> createState() =>
      _AddPaymentScreenState();
}

class _AddPaymentScreenState
    extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  // =============================================================
  // CONTROLLERS
  // =============================================================

  final TextEditingController amountController =
  TextEditingController();

  final TextEditingController notesController =
  TextEditingController();

  // =============================================================
  // DATA
  // =============================================================

  final List<Map<String, dynamic>> members = [];
  bool _isLoadingMembers = true;

  Map<String, dynamic>? selectedMember;

  String selectedCycle = '10 Days';

  String selectedMethod = 'Cash';

  DateTime selectedDate = DateTime.now();

  // =============================================================
  // INIT
  // =============================================================

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
          members.clear();
          for (final m in data) {
            final name = (m['name'] ?? m['farmerName'] ?? '').toString();
            final code = (m['memberCode'] ?? m['id'] ?? '').toString();
            if (name.isNotEmpty) {
              members.add({
                'id': m['id'] ?? code,
                'memberCode': code,
                'name': name,
                'animal': (m['animalType'] ?? m['animal'] ?? 'Cow').toString(),
                'payable': 0.0,
              });
            }
          }
          if (members.isNotEmpty) {
            selectedMember = members.first;
          }
          _isLoadingMembers = false;
        });
        if (selectedMember != null) {
          _updatePayableForSelected();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _updatePayableForSelected() async {
    if (selectedMember == null) return;
    final code = (selectedMember!['memberCode'] ?? selectedMember!['id'] ?? '').toString();
    if (code.isEmpty) return;

    try {
      final totals = await ApiService.getMemberCycleTotals(code);
      String key = 'monthly';
      if (selectedCycle.contains('10')) key = '10_days';
      else if (selectedCycle.contains('15')) key = '15_days';
      else if (selectedCycle.contains('Year')) key = 'yearly';

      final amt = (totals[key]?['amount'] as num?)?.toDouble() ?? 0.0;
      if (mounted) {
        setState(() {
          selectedMember!['payable'] = amt;
          amountController.text = amt > 0 ? amt.toStringAsFixed(0) : '';
        });
      }
    } catch (_) {}
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();

    super.dispose();
  }

  // =============================================================
  // MEMBER CHANGE
  // =============================================================

  void _onMemberChanged(Map<String, dynamic>? member) {
    if (member == null) return;

    setState(() {
      selectedMember = member;
    });
    _updatePayableForSelected();
  }

  // =============================================================
  // DATE PICKER
  // =============================================================

  Future<void> _selectDate() async {
    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // =============================================================
  // SAVE PAYMENT
  // =============================================================

  void _savePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a member'),
        ),
      );

      return;
    }

    final double amount =
        double.tryParse(amountController.text.trim()) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount'),
        ),
      );

      return;
    }

    final payment = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'memberId': selectedMember!['id'],
      'memberCode': selectedMember!['memberCode'] ?? selectedMember!['id'],
      'member': selectedMember!['name'],
      'animal': selectedMember!['animal'],
      'cycle': selectedCycle,
      'amount': amount,
      'method': selectedMethod,
      'date': selectedDate,
      'notes': notesController.text.trim(),
      'status': 'Paid',
    };

    if (widget.onSave != null) {
      widget.onSave!(payment);
    }

    Navigator.pop(context, payment);
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Payment',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14213D),
              ),
            ),

            Text(
              'Record member payment',
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
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              110,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // =================================================
                // MEMBER
                // =================================================

                _fieldLabel('Select Member'),

                const SizedBox(height: 8),

                if (_isLoadingMembers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (members.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFEEBA),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF856404),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No farmers registered yet. Please add a farmer first.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF856404),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(14),

                      border: Border.all(
                        color: const Color(0xFFE1E5EA),
                      ),
                    ),

                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: (selectedMember != null && members.contains(selectedMember))
                            ? selectedMember
                            : null,

                        isExpanded: true,

                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF667085),
                        ),

                        items: members.map((member) {
                          return DropdownMenuItem<
                              Map<String, dynamic>>(
                            value: member,

                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    const Color(
                                      0xFFE7F6F3,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                  ),

                                  child: Icon(
                                    member['animal'] ==
                                        'Cow'
                                        ? Icons
                                        .agriculture_outlined
                                        : Icons
                                        .agriculture,
                                    color:
                                    const Color(
                                      0xFF087F73,
                                    ),
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                    children: [
                                      Text(
                                        member['name'],
                                        style:
                                        const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                          color:
                                          Color(
                                            0xFF14213D,
                                          ),
                                        ),
                                      ),

                                      Text(
                                        member['animal'],
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
                              ],
                            ),
                          );
                        }).toList(),

                        onChanged: _onMemberChanged,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // =================================================
                // PAYMENT CYCLE
                // =================================================

                _fieldLabel('Payment Cycle'),

                const SizedBox(height: 8),

                _cycleSelector(),

                const SizedBox(height: 20),

                // =================================================
                // PAYABLE AMOUNT
                // =================================================

                _fieldLabel('Payable Amount'),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F6F3),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,

                        decoration:
                        BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),

                        child: const Icon(
                          Icons.currency_rupee_rounded,
                          color:
                          Color(0xFF087F73),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Total payable',
                              style:
                              TextStyle(
                                fontSize: 11,
                                color:
                                Color(
                                  0xFF667085,
                                ),
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              '₹${(selectedMember?['payable'] ?? 0).toStringAsFixed(0)}',

                              style:
                              const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(
                                  0xFF14213D,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // PAYMENT AMOUNT
                // =================================================

                _fieldLabel('Payment Amount'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: amountController,
                  inputFormatters: ValidationUtils.decimalNumberFormatter,

                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14213D),
                  ),

                  decoration: _inputDecoration(
                    prefix: '₹ ',
                    hint: 'Enter payment amount',
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter payment amount';
                    }

                    final amount =
                    double.tryParse(
                      value.trim(),
                    );

                    if (amount == null ||
                        amount <= 0) {
                      return 'Enter a valid amount';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // =================================================
                // PAYMENT METHOD
                // =================================================

                _fieldLabel('Payment Method'),

                const SizedBox(height: 8),

                _paymentMethodSelector(),

                const SizedBox(height: 20),

                // =================================================
                // PAYMENT DATE
                // =================================================

                _fieldLabel('Payment Date'),

                const SizedBox(height: 8),

                InkWell(
                  onTap: _selectDate,

                  borderRadius:
                  BorderRadius.circular(14),

                  child: Container(
                    width: double.infinity,

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      border: Border.all(
                        color:
                        const Color(
                          0xFFE1E5EA,
                        ),
                      ),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color:
                          Color(0xFF087F73),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            _formatDate(
                              selectedDate,
                            ),

                            style:
                            const TextStyle(
                              fontSize: 14,
                              color:
                              Color(
                                0xFF14213D,
                              ),
                            ),
                          ),
                        ),

                        const Icon(
                          Icons
                              .keyboard_arrow_down_rounded,
                          color:
                          Color(0xFF667085),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // NOTES
                // =================================================

                _fieldLabel('Notes (Optional)'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: notesController,

                  maxLines: 3,

                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF14213D),
                  ),

                  decoration: _inputDecoration(
                    hint: 'Add payment notes...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // =========================================================
      // SAVE BUTTON
      // =========================================================

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          12,
        ),

        child: SizedBox(
          height: 54,

          child: ElevatedButton(
            onPressed: _savePayment,

            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF087F73),

              foregroundColor: Colors.white,

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(15),
              ),
            ),

            child: const Text(
              'SAVE PAYMENT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FIELD LABEL
  // =============================================================

  Widget _fieldLabel(String text) {
    return Text(
      text,

      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF14213D),
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
      'Yearly',
    ];

    return Container(
      height: 48,

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(13),

        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
      ),

      child: Row(
        children: cycles.map((cycle) {
          final selected =
              selectedCycle == cycle;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCycle = cycle;
                });
                _updatePayableForSelected();
              },

              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 180,
                ),

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: selected
                      ? const Color(
                    0xFFDDF3EF,
                  )
                      : Colors.transparent,

                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),

                child: Text(
                  cycle,

                  style: TextStyle(
                    fontSize: 11,

                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w400,

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
  // PAYMENT METHOD SELECTOR
  // =============================================================

  Widget _paymentMethodSelector() {
    final methods = [
      {
        'name': 'Cash',
        'icon': Icons.payments_outlined,
      },
      {
        'name': 'UPI',
        'icon': Icons.qr_code_2_rounded,
      },
      {
        'name': 'Bank',
        'icon': Icons.account_balance_outlined,
      },
    ];

    return Row(
      children: methods.map((method) {
        final selected =
            selectedMethod == method['name'];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right:
              method['name'] == 'Bank'
                  ? 0
                  : 8,
            ),

            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMethod =
                  method['name'] as String;
                });
              },

              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 180,
                ),

                padding:
                const EdgeInsets.symmetric(
                  vertical: 13,
                ),

                decoration: BoxDecoration(
                  color: selected
                      ? const Color(
                    0xFFE7F6F3,
                  )
                      : Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    13,
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

                child: Column(
                  children: [
                    Icon(
                      method['icon']
                      as IconData,

                      size: 21,

                      color: selected
                          ? const Color(
                        0xFF087F73,
                      )
                          : const Color(
                        0xFF667085,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      method['name']
                      as String,

                      style: TextStyle(
                        fontSize: 11,

                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,

                        color: selected
                            ? const Color(
                          0xFF087F73,
                        )
                            : const Color(
                          0xFF667085,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =============================================================
  // INPUT DECORATION
  // =============================================================

  InputDecoration _inputDecoration({
    String? prefix,
    String? hint,
  }) {
    return InputDecoration(
      prefixText: prefix,

      hintText: hint,

      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF98A2B3),
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFFE1E5EA),
        ),
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFFE1E5EA),
        ),
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFF087F73),
          width: 1.2,
        ),
      ),

      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
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