import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/pdf_download_dialog.dart';

class AnnualBonusScreen extends StatefulWidget {
  const AnnualBonusScreen({super.key});

  @override
  State<AnnualBonusScreen> createState() => _AnnualBonusScreenState();
}

class _AnnualBonusScreenState extends State<AnnualBonusScreen> {
  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color secondaryText = Color(0xFF7A869A);

  bool _isLoading = true;
  double _bonusRate = 1.50;
  List<Map<String, dynamic>> _bonusList = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBonusData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBonusData() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getAnnualBonusList(_bonusRate);
      if (mounted) {
        setState(() {
          _bonusList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bonus data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get totalLitres {
    return _bonusList.fold(
      0.0,
      (sum, item) => sum + ((item['annualLitres'] ?? 0.0) as num).toDouble(),
    );
  }

  double get totalBonusPool {
    return _bonusList.fold(
      0.0,
      (sum, item) => sum + ((item['bonusAmount'] ?? 0.0) as num).toDouble(),
    );
  }

  int get disbursedCount {
    return _bonusList.where((item) => item['status'] == 'Disbursed').length;
  }

  List<Map<String, dynamic>> get filteredList {
    if (_searchQuery.isEmpty) return _bonusList;
    final q = _searchQuery.toLowerCase();
    return _bonusList.where((item) {
      final name = (item['memberName'] ?? '').toString().toLowerCase();
      final code = (item['memberCode'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  void _showChangeRateDialog() {
    final rateCtrl = TextEditingController(text: _bonusRate.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: primary),
              SizedBox(width: 8),
              Text(
                'Configure Bonus Rate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set the annual incentive bonus rate per litre (दर प्रति लिटर) for all members:',
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: ValidationUtils.decimalNumberFormatter,
                decoration: InputDecoration(
                  labelText: 'Rate per Litre (₹/Ltr)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [1.0, 1.25, 1.5, 2.0, 2.5].map((preset) {
                  return ActionChip(
                    label: Text('₹${preset.toStringAsFixed(2)}'),
                    onPressed: () {
                      rateCtrl.text = preset.toStringAsFixed(2);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final newRate = double.tryParse(rateCtrl.text.trim());
                if (newRate != null && newRate > 0) {
                  Navigator.pop(ctx);
                  setState(() {
                    _bonusRate = newRate;
                  });
                  _loadBonusData();
                }
              },
              child: const Text('Apply Rate'),
            ),
          ],
        );
      },
    );
  }

  void _disburseBonus(Map<String, dynamic> item) async {
    final code = item['memberCode']?.toString() ?? '';
    final name = item['memberName']?.toString() ?? '';
    final amount = ((item['bonusAmount'] ?? 0.0) as num).toDouble();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Bonus Disbursement'),
        content: Text(
          'Disburse annual bonus of ₹${amount.toStringAsFixed(2)} to $name ($code)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disburse Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.disburseMemberBonus(code, amount);
      if (mounted) {
        if (success) {
          setState(() {
            item['status'] = 'Disbursed';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bonus of ₹${amount.toStringAsFixed(2)} disbursed to $name!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to record bonus disbursement.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _exportBonusPdf() async {
    final pdfBytes = PdfGeneratorService.generateAnnualBonusPdf(_bonusList, _bonusRate);
    final summaryText = '''
🏆 *ANNUAL BONUS ROSTER (वार्षिक बोनस)*
Rate: ₹${_bonusRate.toStringAsFixed(2)} / Ltr
Total Annual Milk: ${totalLitres.toStringAsFixed(1)} Ltr
Total Bonus Pool: ₹${totalBonusPool.toStringAsFixed(0)}
Beneficiaries: ${_bonusList.length} Farmers
''';
    if (mounted) {
      await PdfDownloadDialog.show(
        context: context,
        title: 'Annual Bonus Roster',
        fileName: 'SmartDairy_AnnualBonus_Roster.pdf',
        pdfBytes: pdfBytes,
        summaryText: summaryText,
      );
    }
  }

  void _shareBonusSlip(Map<String, dynamic> item) {
    final name = item['memberName'] ?? 'Member';
    final bonus = item['bonusAmount'] ?? 0.0;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bonus slip for $name (₹${(bonus as num).toStringAsFixed(2)}) shared via WhatsApp!'),
          backgroundColor: const Color(0xFF25D366),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annual Bonus (वार्षिक बोनस)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Incentive calculation based on annual milk supplied',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export PDF Report',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportBonusPdf,
          ),
          IconButton(
            tooltip: 'Configure Bonus Rate',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showChangeRateDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadBonusData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBonusData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildBonusListSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Annual Milk',
                value: '${totalLitres.toStringAsFixed(1)} L',
                subtitle: 'All members',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _showChangeRateDialog,
                borderRadius: BorderRadius.circular(14),
                child: _statCard(
                  title: 'Bonus Rate',
                  value: '₹${_bonusRate.toStringAsFixed(2)} /L',
                  subtitle: 'Tap to configure',
                  icon: Icons.price_change_outlined,
                  color: primary,
                  showEditBadge: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Bonus Pool',
                value: '₹${totalBonusPool.toStringAsFixed(0)}',
                subtitle: 'Payable pool',
                icon: Icons.monetization_on_outlined,
                color: const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: 'Disbursement',
                value: '$disbursedCount / ${_bonusList.length}',
                subtitle: 'Farmers paid',
                icon: Icons.done_all_rounded,
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool showEditBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (showEditBadge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 10, color: primary),
                      SizedBox(width: 2),
                      Text(
                        'EDIT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search member by name or code...',
        hintStyle: const TextStyle(fontSize: 13, color: secondaryText),
        prefixIcon: const Icon(Icons.search, color: secondaryText),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildBonusListSection() {
    final list = filteredList;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.card_giftcard_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No members found for annual bonus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add members and milk collections to calculate annual bonuses.',
                style: TextStyle(fontSize: 12, color: secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Member Bonus Roster (${list.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            Text(
              'Formula: Litres × ₹${_bonusRate.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final item = list[idx];
            final isDisbursed = item['status'] == 'Disbursed';
            final litres = ((item['annualLitres'] ?? 0.0) as num).toDouble();
            final bonusAmt = ((item['bonusAmount'] ?? 0.0) as num).toDouble();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDisbursed
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primary.withOpacity(0.1),
                        child: Text(
                          item['animalType'] == 'BUFFALO' ? '🐃' : '🐄',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['memberName']?.toString() ?? 'Member',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Code: ${item['memberCode']} • ${item['animalType'] ?? 'COW'}',
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDisbursed
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['status'] ?? 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDisbursed
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Annual Supply',
                            style: TextStyle(
                                fontSize: 10, color: secondaryText),
                          ),
                          Text(
                            '${litres.toStringAsFixed(1)} Ltr',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate',
                            style: TextStyle(
                                fontSize: 10, color: secondaryText),
                          ),
                          Text(
                            '₹${_bonusRate.toStringAsFixed(2)}/L',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Annual Bonus',
                            style: TextStyle(
                                fontSize: 10, color: secondaryText),
                          ),
                          Text(
                            '₹${bonusAmt.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Share Bonus Slip via WhatsApp',
                        icon: const Icon(Icons.share,
                            size: 18, color: Color(0xFF25D366)),
                        onPressed: () => _shareBonusSlip(item),
                      ),
                      const Spacer(),
                      if (!isDisbursed)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text(
                            'Disburse Bonus',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _disburseBonus(item),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Bonus Disbursed',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
