import 'package:flutter/material.dart';

import 'add_milk_sale_screen.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/sync_service.dart';
import '../utils/format_utils.dart';

class MilkSaleScreen extends StatefulWidget {
  const MilkSaleScreen({super.key});

  @override
  State<MilkSaleScreen> createState() => _MilkSaleScreenState();
}

class _MilkSaleScreenState extends State<MilkSaleScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  final List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final data = await ApiService.getMilkSales();
      if (mounted) {
        setState(() {
          _sales.clear();
          for (final item in data) {
            _sales.add({
              'id': item['id'],
              'buyer': item['buyerName'] ?? 'Customer',
              'milk': item['milkType'] ?? 'Cow Milk',
              'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
              'rate': (item['ratePerLitre'] as num?)?.toDouble() ?? 42.0,
              'date': item['date'] ?? 'Today',
              'status': item['status'] ?? 'Paid',
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _visibleSales {
    final query = _searchController.text.trim().toLowerCase();
    return _sales.where((sale) => (_filter == 'All' || sale['status'] == _filter) && (query.isEmpty || sale['buyer'].toString().toLowerCase().contains(query))).toList();
  }

  Future<void> _addSale() async {
    final sale = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const AddMilkSaleScreen()));
    if (sale != null && mounted) {
      setState(() => _sales.insert(0, sale));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Milk sale recorded successfully')));

      final payload = {
        'buyerName': sale['buyer'],
        'milkType': sale['milk'],
        'quantity': sale['quantity'],
        'ratePerLitre': sale['rate'],
        'totalAmount': (sale['quantity'] as double) * (sale['rate'] as double),
        'date': sale['date'],
        'status': sale['status'],
      };

      ApiService.createMilkSale(payload).then((res) {
        if (res == null) SyncService.enqueue('milk_sale', payload);
      }).catchError((_) {
        SyncService.enqueue('milk_sale', payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        final totalMilk = _sales.fold<double>(0, (total, sale) => total + sale['quantity']);
        final totalSale = _sales.fold<double>(0, (total, sale) => total + sale['quantity'] * sale['rate']);
        final pending = _sales.where((sale) => sale['status'] == 'Pending').fold<double>(0, (total, sale) => total + sale['quantity'] * sale['rate']);
        final sales = _visibleSales;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _SaleColors.dark), onPressed: () => Navigator.pop(context)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Milk Sale'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _SaleColors.dark)),
                const Text('Manage outgoing milk sales', style: TextStyle(fontSize: 10, color: _SaleColors.muted)),
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
                  const Text("Today's Sales", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _SaleColors.dark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _summary(Icons.local_drink_outlined, 'Total Milk Sold', FormatUtils.formatQty(totalMilk), _SaleColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _summary(Icons.currency_rupee_rounded, 'Total Sales', FormatUtils.formatCurrency(totalSale), const Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Sales History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _SaleColors.dark)),
                  const SizedBox(height: 10),
                  TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: _input('Search customer / agency...', Icons.search_rounded)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Paid', 'Pending'].map((filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          selectedColor: _SaleColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _filter == filter ? Colors.white : _SaleColors.muted),
                          shape: StadiumBorder(side: BorderSide(color: _filter == filter ? _SaleColors.primary : const Color(0xFFE1E5EA))),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sales.isEmpty) _empty() else ...sales.map((sale) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _saleCard(sale))),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addSale,
            backgroundColor: _SaleColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Sale', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _summary(IconData icon, String label, String value, Color color) => Container(padding: const EdgeInsets.all(13), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 19)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 10, color: _SaleColors.muted)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _SaleColors.dark))]));
  Widget _wideSummary(double pending) => Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFFFF8EA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFE2A8))), child: Row(children: [const Icon(Icons.pending_actions_outlined, color: Color(0xFFF57C00)), const SizedBox(width: 10), const Expanded(child: Text('Pending amount', style: TextStyle(fontSize: 12, color: _SaleColors.muted))), Text(FormatUtils.formatCurrency(pending), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF57C00)))]));
  Widget _saleCard(Map<String, dynamic> sale) {
    final paid = sale['status'] == 'Paid';
    final amount = ((sale['quantity'] as num?)?.toDouble() ?? 0.0) * ((sale['rate'] as num?)?.toDouble() ?? 0.0);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _card(),
      child: Column(children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0xFFE7F6F3), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined, color: _SaleColors.primary, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sale['buyer'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _SaleColors.dark)),
              const SizedBox(height: 2),
              Text('${sale['milk']} • ${sale['date']}', style: const TextStyle(fontSize: 10, color: _SaleColors.muted)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: paid ? const Color(0xFFEAF7EC) : const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
            child: Text(sale['status'], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: paid ? const Color(0xFF3C9145) : const Color(0xFFF57C00))),
          ),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Divider(height: 1, color: Color(0xFFEDF0F2))),
        Row(children: [
          _detail('Quantity', FormatUtils.formatQty(sale['quantity'])),
          _detail('Rate', FormatUtils.formatRate(sale['rate'])),
          _detail('Amount', FormatUtils.formatCurrency(amount), highlight: true),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: _SaleColors.muted),
            onPressed: () => _showSaleOptions(sale),
          ),
        ]),
      ]),
    );
  }

  void _showSaleOptions(Map<String, dynamic> sale) {
    final isPaid = sale['status'] == 'Paid';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(isPaid ? Icons.pending_outlined : Icons.check_circle_outline, color: isPaid ? const Color(0xFFF57C00) : const Color(0xFF3C9145)),
              title: Text(isPaid ? 'Mark as Pending' : 'Mark as Paid'),
              subtitle: Text(isPaid ? 'Change status back to pending' : 'Record payment received for this sale'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => sale['status'] = isPaid ? 'Pending' : 'Paid');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale status updated to ${sale['status']}')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Sale Record', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _sales.remove(sale));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale record deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _detail(String label, String value, {bool highlight = false}) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: _SaleColors.muted)), const SizedBox(height: 3), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlight ? _SaleColors.primary : _SaleColors.dark))]));
  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _SaleColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.point_of_sale_rounded, size: 36, color: _SaleColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No External Milk Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _SaleColors.dark)),
          const SizedBox(height: 6),
          const Text('Record direct milk sales to dairies, hotels, sweet shops, or local buyers.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _SaleColors.muted)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _addSale,
            style: ElevatedButton.styleFrom(
              backgroundColor: _SaleColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Record Milk Sale', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _input(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _SaleColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _SaleColors.primary)));
BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E5EA)));
class _SaleColors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
