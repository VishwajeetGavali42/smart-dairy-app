import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../bonus/annual_bonus_screen.dart';
import '../invoice/detailed_bill_statement_screen.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/pdf_download_dialog.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const ReportsScreen({super.key, this.onBackToDashboard});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'This Month';

  final Map<String, Map<String, dynamic>> _reportData = {
    'This Week': {
      'collection': '845.5 Ltr',
      'revenue': '₹36,250',
      'expenses': '₹4,500',
      'netProfit': '₹31,750',
      'trendTitle': 'Daily collection (This Week)',
      'trendGrowth': '+8.4%',
      'bars': [0.65, 0.72, 0.68, 0.85, 0.78, 0.92, 0.88],
      'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      'memberPayments': '₹31,500 paid to 5 members',
      'memberPaymentsDetail': 'Daily collection payouts via Direct Bank & Cash.',
      'salesDesc': 'Local retail milk sales: 125 Ltr at ₹52/Ltr.',
      'deductions': '₹3,200 feed & advance recovered',
      'qualityFat': '5.2% Avg FAT',
      'qualityDesc': 'Standard Grade meeting high purity benchmarks.',
    },
    'This Month': {
      'collection': '3,620 Ltr',
      'revenue': '₹1,58,400',
      'expenses': '₹18,500',
      'netProfit': '₹1,39,900',
      'trendTitle': 'Weekly milk collection',
      'trendGrowth': '+12.6%',
      'bars': [0.70, 0.78, 0.85, 0.90, 0.82, 0.95, 0.88],
      'labels': ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Avg', 'Peak', 'Cur'],
      'memberPayments': '₹1,35,000 paid to 12 members',
      'memberPaymentsDetail': 'Cycle-wise settlements for 10-day & monthly farmers.',
      'salesDesc': '520 Ltr local sales + 3,100 Ltr tanker plant dispatch.',
      'deductions': '₹12,500 cattle feed & veterinary loan deductions.',
      'qualityFat': '5.4% Avg FAT',
      'qualityDesc': 'High quality dairy yield: Cow 4.2% FAT, Buffalo 6.8% FAT.',
    },
    'This Year': {
      'collection': '42,800 Ltr',
      'revenue': '₹18,60,000',
      'expenses': '₹2,10,000',
      'netProfit': '₹16,50,000',
      'trendTitle': 'Monthly collection overview',
      'trendGrowth': '+18.2%',
      'bars': [0.55, 0.65, 0.72, 0.80, 0.88, 0.92, 0.85],
      'labels': ['Jan-Feb', 'Mar-Apr', 'May-Jun', 'Jul-Aug', 'Sep-Oct', 'Nov', 'Dec'],
      'memberPayments': '₹15,80,000 paid to registered farmers',
      'memberPaymentsDetail': 'Annual society billing & member bonus distribution.',
      'salesDesc': 'Annual bulk dispatch to regional co-operative plant.',
      'deductions': '₹1,45,000 seasonal advance & feed recovery.',
      'qualityFat': '5.3% Avg FAT',
      'qualityDesc': 'Consistent top-tier chilling center purity score.',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLiveMetrics();
  }

  Future<void> _loadLiveMetrics() async {
    try {
      final summary = await ApiService.getTodaySummary();
      if (mounted) {
        setState(() {
          final totalLiters = summary['totalMilk'] ?? summary['totalLiters'];
          final totalAmount = summary['totalAmount'];
          final avgFat = summary['avgFat'];
          final avgSnf = summary['avgSnf'];

          if (totalLiters != null && (totalLiters as num) > 0) {
            _reportData['This Week']!['collection'] = '$totalLiters Ltr (Today live)';
          }
          if (totalAmount != null && (totalAmount as num) > 0) {
            _reportData['This Week']!['revenue'] = '₹$totalAmount (Today live)';
          }
          if (avgFat != null && (avgFat as num) > 0) {
            _reportData['This Week']!['qualityFat'] = '${(avgFat as num).toStringAsFixed(1)}% Avg FAT';
            _reportData['This Week']!['qualityDesc'] = 'Live: FAT ${(avgFat as num).toStringAsFixed(1)}% • SNF ${(avgSnf != null ? (avgSnf as num).toStringAsFixed(1) : "8.7")}%';
          }
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic> get _currentData => _reportData[_period]!;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        final data = _currentData;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _ReportColors.dark),
          onPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ReportColors.dark)),
            Text('Dairy performance overview',
                style: TextStyle(fontSize: 10, color: _ReportColors.muted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showExportDialog(),
            icon: const Icon(Icons.file_download_outlined,
                color: _ReportColors.primary),
            tooltip: 'Export report',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _periodSelector(),
              const SizedBox(height: 20),
              const Text('Business Summary',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ReportColors.dark)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _metric(Icons.local_drink_outlined, 'Collection', data['collection'], _ReportColors.primary),
                  _metric(Icons.currency_rupee_rounded, 'Revenue', data['revenue'], const Color(0xFF55A85B)),
                  _metric(Icons.account_balance_wallet_outlined, 'Expenses', data['expenses'], const Color(0xFFF57C00)),
                  _metric(Icons.trending_up_rounded, 'Net Profit', data['netProfit'], const Color(0xFF4B8EF7)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Collection Trend',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ReportColors.dark)),
              const SizedBox(height: 10),
              _trendCard(data),
              const SizedBox(height: 24),
              const Text('Report Details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ReportColors.dark)),
              const SizedBox(height: 10),
              _detailTile(
                Icons.groups_outlined,
                'Member Payments',
                data['memberPayments'],
                const Color(0xFF8E63CE),
                onTap: () => _showDetailReport(
                  'Member Payments',
                  const Color(0xFF8E63CE),
                  Icons.groups_outlined,
                  data['revenue'],
                  data['memberPaymentsDetail'],
                ),
              ),
              const SizedBox(height: 9),
              _detailTile(
                Icons.storefront_outlined,
                'Milk Sales',
                '${data['revenue']} from external sales',
                _ReportColors.primary,
                onTap: () => _showDetailReport(
                  'Milk Sales',
                  _ReportColors.primary,
                  Icons.storefront_outlined,
                  data['revenue'],
                  data['salesDesc'],
                ),
              ),
              const SizedBox(height: 9),
              _detailTile(
                Icons.percent_rounded,
                'Deductions',
                data['deductions'],
                const Color(0xFFF57C00),
                onTap: () => _showDetailReport(
                  'Deductions',
                  const Color(0xFFF57C00),
                  Icons.percent_rounded,
                  data['expenses'],
                  'Deductions recovered for feed, equipment, advances, and insurance.',
                ),
              ),
              const SizedBox(height: 9),
              _detailTile(
                Icons.verified_outlined,
                'Milk Quality',
                data['qualityDesc'].toString().split('.').first,
                const Color(0xFF55A85B),
                onTap: () => _showDetailReport(
                  'Milk Quality',
                  const Color(0xFF55A85B),
                  Icons.verified_outlined,
                  data['qualityFat'],
                  data['qualityDesc'],
                ),
              ),
              const SizedBox(height: 9),
              _detailTile(
                Icons.stars_rounded,
                'Annual Member Bonus (वार्षिक बोनस)',
                'Yearly milk supply incentive roster',
                const Color(0xFF15803D),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnnualBonusScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
              _detailTile(
                Icons.table_chart_outlined,
                'Detailed Cycle Statement (१० दिवसीय बिल)',
                'Shift-wise collections, feed & deductions',
                const Color(0xFF1E3A8A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DetailedBillStatementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _periodSelector() {
    const periods = ['This Week', 'This Month', 'This Year'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      child: Row(
        children: periods.map((period) {
          final selected = _period == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFDDF3EF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(period,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? _ReportColors.primary : _ReportColors.muted)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metric(IconData icon, String title, String value, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: _card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 18)),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 10, color: _ReportColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ReportColors.dark)),
        ]),
      );

  Widget _trendCard(Map<String, dynamic> data) {
    final bars = data['bars'] as List<double>;
    final labels = data['labels'] as List<String>;
    return Container(
      height: 205,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(data['trendTitle'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ReportColors.dark)), const Spacer(), Text(data['trendGrowth'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green.shade700))]),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              bars.length,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 18,
                            height: 118 * bars[index],
                            decoration: BoxDecoration(
                              color: index == bars.length - 2
                                  ? _ReportColors.primary
                                  : const Color(0xFFB8DCD6),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: _ReportColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _detailTile(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    required VoidCallback onTap,
  }) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: _card(),
          child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 21)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ReportColors.dark)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 10, color: _ReportColors.muted))])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ]),
        ),
      );

  void _showDetailReport(
    String title,
    Color color,
    IconData icon,
    String value,
    String description,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFE1E5EA), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ReportColors.dark)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 12),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.45, color: _ReportColors.muted)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(foregroundColor: _ReportColors.primary, side: const BorderSide(color: _ReportColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Close'))),
          ]),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export $_period Report', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ReportColors.dark)),
              const SizedBox(height: 8),
              const Text('Select your desired export format for dairy accounting records.', style: TextStyle(fontSize: 12, color: _ReportColors.muted)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                ),
                title: const Text('Export as PDF Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Complete printable breakdown with charts and metrics', style: TextStyle(fontSize: 11, color: _ReportColors.muted)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  final pdfBytes = PdfGeneratorService.generateSummaryReportPdf(
                    _period,
                    _currentData,
                  );
                  final safePeriod = _period.replaceAll(' ', '_');
                  PdfDownloadDialog.show(
                    context: context,
                    fileName: 'SmartDairy_Report_$safePeriod.pdf',
                    pdfBytes: pdfBytes,
                    title: 'Executive $_period Report PDF',
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.table_chart_outlined, color: Colors.green),
                ),
                title: const Text('Export as Excel / CSV', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Raw ledger entries for tally and spreadsheet auditing', style: TextStyle(fontSize: 11, color: _ReportColors.muted)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_period Ledger exported as CSV successfully!'),
                      backgroundColor: const Color(0xFF55A85B),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E5EA)));
class _ReportColors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
