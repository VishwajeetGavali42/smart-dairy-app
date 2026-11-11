import 'package:flutter/material.dart';

import 'add_received_screen.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/sync_service.dart';
import '../utils/format_utils.dart';

class ReceivedScreen extends StatefulWidget { const ReceivedScreen({super.key}); @override State<ReceivedScreen> createState() => _ReceivedScreenState(); }
class _ReceivedScreenState extends State<ReceivedScreen> {
  final _search = TextEditingController(); String _filter = 'All';
  final List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadReceived();
  }

  Future<void> _loadReceived() async {
    try {
      final data = await ApiService.getReceived();
      if (mounted) {
        setState(() {
          _records.clear();
          for (final item in data) {
            _records.add({
              'id': item['id'],
              'source': item['source'] ?? 'Center',
              'type': item['milkType'] ?? item['type'] ?? 'Cow Milk',
              'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
              'quality': item['quality'] ?? (item['fat'] != null ? 'FAT ${item['fat']}%' : 'Grade A (4.2% FAT)'),
              'date': item['date'] ?? 'Today',
              'status': item['status'] ?? 'Accepted',
            });
          }
        });
      }
    } catch (_) {}
  }

  @override void dispose() { _search.dispose(); super.dispose(); }
  List<Map<String, dynamic>> get _visible => _records.where((item) { final q = _search.text.trim().toLowerCase(); return (_filter == 'All' || item['status'] == _filter) && (q.isEmpty || item['source'].toString().toLowerCase().contains(q)); }).toList();

  Future<void> _add() async {
    final result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const AddReceivedScreen()));
    if (result != null && mounted) {
      setState(() => _records.insert(0, result));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Milk receipt saved successfully')));

      final payload = {
        'source': result['source'],
        'milkType': result['type'],
        'quantity': result['quantity'],
        'fat': 4.5,
        'snf': 8.5,
        'date': result['date'],
        'status': result['status'],
      };

      ApiService.createReceived(payload).then((res) {
        if (res == null) SyncService.enqueue('received', payload);
      }).catchError((_) {
        SyncService.enqueue('received', payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        final total = _records.fold<double>(0, (sum, item) => sum + item['quantity']);
        final accepted = _records.where((item) => item['status'] == 'Accepted').fold<double>(0, (sum, item) => sum + item['quantity']);
        final records = _visible;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _ReceivedColors.dark), onPressed: () => Navigator.pop(context)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Received'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ReceivedColors.dark)),
                const Text('Track incoming milk', style: TextStyle(fontSize: 10, color: _ReceivedColors.muted)),
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
                  const Text("Today's Receipts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ReceivedColors.dark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _summary(Icons.inventory_2_outlined, 'Total Received', FormatUtils.formatQty(total), _ReceivedColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _summary(Icons.verified_outlined, 'Accepted', FormatUtils.formatQty(accepted), const Color(0xFF55A85B))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Receipt History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ReceivedColors.dark)),
                  const SizedBox(height: 10),
                  TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: _input('Search source...', Icons.search_rounded)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Accepted', 'Pending'].map((item) => ChoiceChip(
                      label: Text(item),
                      selected: _filter == item,
                      onSelected: (_) => setState(() => _filter = item),
                      selectedColor: _ReceivedColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _filter == item ? Colors.white : _ReceivedColors.muted),
                      shape: StadiumBorder(side: BorderSide(color: _filter == item ? _ReceivedColors.primary : const Color(0xFFE1E5EA))),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  if (records.isEmpty) _empty() else ...records.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _record(item))),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            backgroundColor: _ReceivedColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Receipt', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
  Widget _summary(IconData icon, String title, String value, Color color) => Container(padding: const EdgeInsets.all(13), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 19)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 10, color: _ReceivedColors.muted)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ReceivedColors.dark))]));
  Widget _record(Map<String, dynamic> item) {
    final accepted = item['status'] == 'Accepted';
    final color = accepted ? const Color(0xFF3C9145) : const Color(0xFFF57C00);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _card(),
      child: Column(children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0xFFE7F6F3), shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_outlined, color: _ReceivedColors.primary, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['source'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ReceivedColors.dark)),
              const SizedBox(height: 2),
              Text('${item['type']} • ${item['date']}', style: const TextStyle(fontSize: 10, color: _ReceivedColors.muted)),
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
          const SizedBox(width: 24),
          _detail(Icons.water_drop_outlined, item['quality']),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: _ReceivedColors.muted),
            onPressed: () => _showReceivedOptions(item),
          ),
        ]),
      ]),
    );
  }

  void _showReceivedOptions(Map<String, dynamic> item) {
    final isAccepted = item['status'] == 'Accepted';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(isAccepted ? Icons.pending_outlined : Icons.check_circle_outline, color: isAccepted ? const Color(0xFFF57C00) : const Color(0xFF3C9145)),
              title: Text(isAccepted ? 'Mark as Pending Review' : 'Mark as Accepted'),
              subtitle: Text(isAccepted ? 'Hold for laboratory test verification' : 'Confirm milk quality and accept load'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => item['status'] = isAccepted ? 'Pending' : 'Accepted');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to ${item['status']}')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Receipt Record', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _records.remove(item));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Milk receipt record deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: _ReceivedColors.muted), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 10, color: _ReceivedColors.muted))]);
  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _ReceivedColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 36, color: _ReceivedColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No Received Milk Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ReceivedColors.dark)),
          const SizedBox(height: 6),
          const Text('Log incoming bulk milk receipts from suppliers and external collection centers.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _ReceivedColors.muted)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _add,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ReceivedColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Record Milk Receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}
InputDecoration _input(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)), prefixIcon: Icon(icon, color: _ReceivedColors.primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE1E5EA))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _ReceivedColors.primary))); BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E5EA))); class _ReceivedColors { static const primary = Color(0xFF087F73); static const dark = Color(0xFF14213D); static const muted = Color(0xFF7A869A); }
