import 'package:flutter/material.dart';

import 'add_dispatch_screen.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/sync_service.dart';
import '../utils/format_utils.dart';

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final _search = TextEditingController();
  String _filter = 'All';
  final List<Map<String, dynamic>> _dispatches = [];

  @override
  void initState() {
    super.initState();
    _loadDispatches();
  }

  Future<void> _loadDispatches() async {
    try {
      final data = await ApiService.getDispatches();
      if (mounted) {
        setState(() {
          _dispatches.clear();
          for (final item in data) {
            _dispatches.add({
              'id': item['id'],
              'destination': item['destination'] ?? 'Dairy Plant',
              'type': item['milkType'] ?? item['animalType'] ?? 'Cow Milk',
              'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
              'vehicle': item['vehicleNo'] ?? item['tankerNo'] ?? 'Tanker',
              'date': item['date'] ?? 'Today',
              'status': item['status'] ?? 'Dispatched',
            });
          }
        });
      }
    } catch (_) {}
  }

  @override void dispose() { _search.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _visible => _dispatches.where((item) { final q = _search.text.trim().toLowerCase(); return (_filter == 'All' || item['status'] == _filter) && (q.isEmpty || item['destination'].toString().toLowerCase().contains(q) || item['vehicle'].toString().toLowerCase().contains(q)); }).toList();

  Future<void> _add() async {
    final item = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const AddDispatchScreen()));
    if (item != null && mounted) {
      setState(() => _dispatches.insert(0, item));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispatch recorded successfully')));

      final payload = {
        'destination': item['destination'],
        'milkType': item['type'],
        'quantity': item['quantity'],
        'vehicleNo': item['vehicle'],
        'date': item['date'],
        'status': item['status'],
      };

      ApiService.createDispatch(payload).then((res) {
        if (res == null) SyncService.enqueue('dispatch', payload);
      }).catchError((_) {
        SyncService.enqueue('dispatch', payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        final total = _dispatches.fold<double>(0, (sum, item) => sum + item['quantity']);
        final transit = _dispatches.where((item) => item['status'] == 'In Transit').fold<double>(0, (sum, item) => sum + item['quantity']);
        final records = _visible;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _DispatchColors.dark), onPressed: () => Navigator.pop(context)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dispatch'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _DispatchColors.dark)),
                const Text('Track outgoing milk loads', style: TextStyle(fontSize: 10, color: _DispatchColors.muted)),
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
                  const Text("Today's Dispatch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DispatchColors.dark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _summary(Icons.local_shipping_outlined, 'Total Dispatched', FormatUtils.formatQty(total), _DispatchColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _summary(Icons.route_outlined, 'In Transit', FormatUtils.formatQty(transit), const Color(0xFFF57C00))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Dispatch History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DispatchColors.dark)),
                  const SizedBox(height: 10),
                  TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: _input('Search destination or vehicle...', Icons.search_rounded)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Dispatched', 'In Transit', 'Delivered'].map((filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          selectedColor: _DispatchColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _filter == filter ? Colors.white : _DispatchColors.muted),
                          shape: StadiumBorder(side: BorderSide(color: _filter == filter ? _DispatchColors.primary : const Color(0xFFE1E5EA))),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (records.isEmpty) _empty() else ...records.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _record(item))),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            backgroundColor: _DispatchColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Dispatch', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
  Widget _summary(IconData icon, String title, String value, Color color) => Container(padding: const EdgeInsets.all(13), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 19)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 10, color: _DispatchColors.muted)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DispatchColors.dark))]));
  Widget _record(Map<String, dynamic> item) {
    final color = item['status'] == 'Delivered'
        ? const Color(0xFF3C9145)
        : item['status'] == 'In Transit'
            ? const Color(0xFFF57C00)
            : _DispatchColors.primary;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _card(),
      child: Column(children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0xFFE7F6F3), shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_outlined, color: _DispatchColors.primary, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['destination'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _DispatchColors.dark)),
              const SizedBox(height: 2),
              Text('${item['type']} • ${item['date']}', style: const TextStyle(fontSize: 10, color: _DispatchColors.muted)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(12)),
            child: Text(item['status'], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Divider(height: 1, color: Color(0xFFEDF0F2))),
        Row(children: [
          _detail(Icons.local_drink_outlined, FormatUtils.formatQty(item['quantity'])),
          const SizedBox(width: 18),
          _detail(Icons.directions_car_outlined, item['vehicle']),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: _DispatchColors.muted),
            onPressed: () => _showDispatchOptions(item),
          ),
        ]),
      ]),
    );
  }

  void _showDispatchOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.sync_alt_rounded, color: _DispatchColors.primary),
              title: const Text('Update Status'),
              subtitle: Text('Current: ${item['status']}'),
              onTap: () {
                Navigator.pop(ctx);
                _showStatusUpdateDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF4B8EF7)),
              title: const Text('View Full Details'),
              onTap: () {
                Navigator.pop(ctx);
                _showDetailsDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Dispatch', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _dispatches.remove(item));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispatch record deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Dispatch Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        children: ['Dispatched', 'In Transit', 'Delivered'].map((status) => SimpleDialogOption(
          onPressed: () {
            setState(() => item['status'] = status);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  item['status'] == status ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: item['status'] == status ? _DispatchColors.primary : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(status, style: TextStyle(fontWeight: item['status'] == status ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['destination'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow('Milk Type', item['type']),
            _dialogRow('Quantity', FormatUtils.formatQty(item['quantity'], 'Litres')),
            _dialogRow('Vehicle No.', item['vehicle']),
            _dialogRow('Dispatch Date', item['date']),
            _dialogRow('Status', item['status']),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE', style: TextStyle(color: _DispatchColors.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _DispatchColors.muted, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _DispatchColors.dark)),
      ],
    ),
  );
  Widget _detail(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: _DispatchColors.muted), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 10, color: _DispatchColors.muted))]);
  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _DispatchColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_outlined, size: 36, color: _DispatchColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No Tanker Dispatches Recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DispatchColors.dark)),
          const SizedBox(height: 6),
          const Text('Track milk tanker shipments to chilling centers and processing plants.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _DispatchColors.muted)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _add,
            style: ElevatedButton.styleFrom(
              backgroundColor: _DispatchColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Record First Dispatch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}
InputDecoration _input(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _DispatchColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _DispatchColors.primary)));
BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E5EA)));
class _DispatchColors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
