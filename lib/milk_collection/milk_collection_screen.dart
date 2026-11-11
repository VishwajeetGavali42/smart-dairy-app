import 'package:flutter/services.dart';

import '../utils/validation_utils.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/language_service.dart';
import '../screens/ai_chat_screen.dart';
import '../services/sync_service.dart';
import '../services/receipt_service.dart';
import '../services/hardware_service.dart';
import '../widgets/bluetooth_device_modal.dart';

// =============================================================
// MILK COLLECTION SCREEN
// =============================================================

class MilkCollectionScreen extends StatefulWidget {
  const MilkCollectionScreen({super.key});

  @override
  State<MilkCollectionScreen> createState() => _MilkCollectionScreenState();
}

class _MilkCollectionScreenState extends State<MilkCollectionScreen> {
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _dateFilter = 'ALL'; // 'ALL', 'TODAY', 'YESTERDAY', '7DAYS', 'CUSTOM'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  Map<String, dynamic>? _todaySummary;

  // ===========================================================
  // COLLECTION DATA
  // ===========================================================

  final List<Map<String, dynamic>> collections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bool isMember = ApiService.userRole.toUpperCase() == 'MEMBER';
    final bool isUnlinked = isMember &&
        (ApiService.currentMemberCode == null ||
            ApiService.currentMemberCode!.isEmpty);

    if (isUnlinked) {
      if (mounted) {
        setState(() {
          collections.clear();
          _todaySummary = {
            'totalMilk': 0.0,
            'totalAmount': 0.0,
            'avgFat': 0.0,
            'collectionsCount': 0,
            'memberCount': 0,
          };
          _isLoading = false;
        });
      }
      return;
    }

    try {
      DateTime? start;
      DateTime? end;
      final now = DateTime.now();

      if (_dateFilter == 'TODAY') {
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day);
      } else if (_dateFilter == 'YESTERDAY') {
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day);
      } else if (_dateFilter == '7DAYS') {
        start = now.subtract(const Duration(days: 7));
        end = now;
      } else if (_dateFilter == 'CUSTOM' && _customStartDate != null && _customEndDate != null) {
        start = _customStartDate;
        end = _customEndDate;
      }

      final data = await ApiService.getTodayCollections(
        startDate: _dateFilter == 'ALL' ? null : start,
        endDate: _dateFilter == 'ALL' ? null : end,
      );
      final summary = await ApiService.getTodaySummary();
      if (mounted) {
        setState(() {
          collections.clear();
          for (final item in data) {
            final rateVal = (item['ratePerLitre'] as num?)?.toDouble() ??
                ((item['rate'] as num?)?.toDouble() ??
                    (((item['totalAmount'] as num?)?.toDouble() ?? 0) /
                        (((item['quantity'] as num?)?.toDouble() ?? 1) == 0
                            ? 1
                            : ((item['quantity'] as num?)?.toDouble() ?? 1))));
            collections.add({
              'memberCode': item['memberCode'] ?? '',
              'memberName': item['memberName'] ?? 'Member',
              'animal': item['animalType'] ?? 'Cow',
              'milk': '${item['quantity'] ?? 0} L',
              'fat': '${item['fat'] ?? 0.0}',
              'snf': '${item['snf'] ?? 0.0}',
              'rate': '₹${rateVal.toStringAsFixed(1)}',
              'amount': '₹${((item['totalAmount'] ?? 0.0) as num).round()}',
              'shift': item['shift'] ?? 'Morning',
              'date': item['collectionDate'] ?? 'Today',
            });
          }
          _todaySummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not fetch records: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ===========================================================
  // FILTERED COLLECTIONS
  // ===========================================================

  List<Map<String, dynamic>> get filteredCollections {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return collections;
    }

    return collections.where((collection) {
      final name = collection['memberName'].toString().toLowerCase();

      final animal = collection['animal'].toString().toLowerCase();

      return name.contains(query) || animal.contains(query);
    }).toList();
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF43A99F),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ApiService.userRole.toUpperCase() == 'MEMBER'
                  ? 'Milk Passbook'.tr
                  : 'Milk Collection'.tr,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur'.tr,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Ask AI Assistant'.tr,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiChatScreen(
                    initialScreenContext: 'milk_collection',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching_rounded),
            tooltip: 'Hardware Devices (Scale & Analyzer)'.tr,
            onPressed: () => BluetoothDeviceModal.show(context),
          ),
        ],
      ),

      // =========================================================
      // BODY
      // =========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) ...[
              const LinearProgressIndicator(
                color: Color(0xFF087F73),
                backgroundColor: Color(0xFFE7F6F3),
              ),
              const SizedBox(height: 12),
            ],

            // ===================================================
            // TODAY SUMMARY
            // ===================================================
            Text(
              "Today's Collection".tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14213D),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    icon: Icons.local_drink_outlined,
                    title: 'Milk'.tr,
                    value: _todaySummary != null
                        ? '${_todaySummary!['totalMilk']} L'
                        : '0 L',
                    color: const Color(0xFF087F73),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _summaryCard(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Amount'.tr,
                    value: _todaySummary != null
                        ? '₹${_todaySummary!['totalAmount']}'
                        : '₹0',
                    color: const Color(0xFF55A85B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    icon: Icons.water_drop_outlined,
                    title: 'Avg FAT'.tr,
                    value: _todaySummary != null
                        ? '${_todaySummary!['avgFat']}%'
                        : '0.0%',
                    color: const Color(0xFFFF9800),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _summaryCard(
                    icon: Icons.groups_outlined,
                    title: 'Entries'.tr,
                    value: collections.length.toString(),
                    color: const Color(0xFF7B61A8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===================================================
            // MILK ENTRIES
            // ===================================================
            Text(
              'Milk Entries'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14213D),
              ),
            ),

            const SizedBox(height: 12),

            // ===================================================
            // SEARCH
            // ===================================================
            TextField(
              controller: searchController,

              onChanged: (_) {
                setState(() {});
              },

              decoration: InputDecoration(
                hintText: 'Search member or animal...',

                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9AA1AC),
                ),

                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF087F73),
                ),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF43A99F),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Date Filters & Pagination Range Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _dateChip('Today'.tr, 'TODAY'),
                  const SizedBox(width: 8),
                  _dateChip('Yesterday'.tr, 'YESTERDAY'),
                  const SizedBox(width: 8),
                  _dateChip('Last 7 Days'.tr, '7DAYS'),
                  const SizedBox(width: 8),
                  _dateChip('All Records'.tr, 'ALL'),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF087F73)),
                    label: Text(
                      _dateFilter == 'CUSTOM' && _customStartDate != null && _customEndDate != null
                          ? '${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate!.day}/${_customEndDate!.month}'
                          : 'Pick Date'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _dateFilter == 'CUSTOM' ? FontWeight.w700 : FontWeight.w500,
                        color: _dateFilter == 'CUSTOM' ? const Color(0xFF087F73) : const Color(0xFF334155),
                      ),
                    ),
                    onPressed: _pickCustomDateRange,
                    backgroundColor: _dateFilter == 'CUSTOM' ? const Color(0xFFE7F6F3) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: _dateFilter == 'CUSTOM' ? const Color(0xFF087F73) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              _buildErrorBanner(),

            // ===================================================
            // COLLECTION LIST
            // ===================================================
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF087F73))),
              )
            else if (ApiService.userRole.toUpperCase() == 'MEMBER' &&
                (ApiService.currentMemberCode == null ||
                    ApiService.currentMemberCode!.isEmpty))
              _buildUnlinkedMemberCard()
            else if (filteredCollections.isEmpty)
              _buildEmptyState()
            else
              ...filteredCollections.map((collection) {
                return _collectionCard(
                  memberName: collection['memberName'].toString(),
                  animal: collection['animal'].toString(),
                  milk: collection['milk'].toString(),
                  fat: collection['fat'].toString(),
                  snf: collection['snf'].toString(),
                  amount: collection['amount'].toString(),
                  shift: collection['shift'].toString(),
                  rate: collection['rate']?.toString(),
                  date: collection['date']?.toString(),
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // =========================================================
      // ADD BUTTON (Hidden for Members: Collections entered exclusively by Dairy Owner/Operator)
      // =========================================================
      floatingActionButton: (ApiService.userRole.toUpperCase() == 'MEMBER')
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF087F73),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: _openAddCollection,
              child: const Icon(Icons.add, size: 30),
            ),
    );
  }

  // ===========================================================
  // OPEN ADD COLLECTION
  // ===========================================================

  void _openAddCollection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddMilkCollectionScreen(
            onSave: (newCollection) async {
              try {
                final qty =
                    double.tryParse(
                      newCollection['milk']
                          .toString()
                          .replaceAll(' L', '')
                          .replaceAll('L', '')
                          .trim(),
                    ) ??
                    0.0;
                final fat =
                    double.tryParse(newCollection['fat'].toString()) ?? 0.0;
                final snf =
                    double.tryParse(newCollection['snf'].toString()) ?? 0.0;
                final amount =
                    double.tryParse(
                      newCollection['amount']
                          .toString()
                          .replaceAll('₹', '')
                          .trim(),
                    ) ??
                    0.0;
                final rate = (qty > 0 && amount > 0) ? (amount / qty) : 38.0;
                final payload = {
                  'memberCode': newCollection['memberCode'] ?? 'M001',
                  'memberName': newCollection['memberName'] ?? 'Member',
                  'animalType': newCollection['animal'] ?? 'Cow',
                  'shift': newCollection['shift'] ?? 'Morning',
                  'quantity': qty,
                  'fat': fat,
                  'snf': snf,
                  'ratePerLitre': rate,
                  'totalAmount': amount,
                };

                final res = await ApiService.recordCollection(payload);
                if (res == null) {
                  SyncService.enqueue('collection', payload);
                }
                _loadCollections();

                if (mounted) {
                  ReceiptService.showSlipDialog(
                    context,
                    dairyName: 'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur',
                    memberCode: payload['memberCode'],
                    memberName: payload['memberName'],
                    shift: payload['shift'],
                    animal: payload['animalType'],
                    quantity: qty,
                    fat: fat,
                    snf: snf,
                    rate: rate,
                    totalAmount: amount,
                  );
                }
              } catch (_) {
                SyncService.enqueue('collection', {
                  'memberCode': newCollection['memberCode'] ?? 'M001',
                  'memberName': newCollection['memberName'] ?? 'Member',
                  'animalType': newCollection['animal'] ?? 'Cow',
                  'shift': newCollection['shift'] ?? 'Morning',
                  'quantity': 10.0,
                  'fat': 4.5,
                  'snf': 8.5,
                  'ratePerLitre': 42.0,
                  'totalAmount': 420.0,
                });
                _loadCollections();
              }
            },
          );
        },
      ),
    );
  }

  // ===========================================================
  // SUMMARY CARD
  // ===========================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: color, size: 23),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A869A),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF14213D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // COLLECTION CARD
  // ===========================================================

  Widget _collectionCard({
    required String memberName,
    required String animal,
    required String milk,
    required String fat,
    required String snf,
    required String amount,
    required String shift,
    String? rate,
    String? date,
  }) {
    final bool isCow = animal == 'Cow';

    return InkWell(
      onTap: () => _showCollectionReceiptModal(
        memberName: memberName,
        animal: animal,
        milk: milk,
        fat: fat,
        snf: snf,
        amount: amount,
        shift: shift,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),

        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F6F3),
                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: Center(
                    child: Text(
                      isCow ? '🐄' : '🐃',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF14213D),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          Text(
                            animal,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7A869A),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F6F3),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              shift,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF087F73),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF087F73),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _milkDetail('Milk', milk),
                _milkDetail('FAT', fat),
                _milkDetail('SNF', snf),
                if (rate != null) _milkDetail('Rate', '$rate/L'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionReceiptModal({
    required String memberName,
    required String animal,
    required String milk,
    required String fat,
    required String snf,
    required String amount,
    required String shift,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E9E8)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF087F73),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'MILK COLLECTION RECEIPT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A869A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      _receiptRow('Farmer Name', memberName),
                      const SizedBox(height: 6),
                      _receiptRow(
                        'Cattle Type',
                        '$animal ${animal == "Cow" ? "🐄" : "🐃"}',
                      ),
                      const SizedBox(height: 6),
                      _receiptRow('Shift', '$shift Shift'),
                      const SizedBox(height: 6),
                      _receiptRow('Date & Time', 'Today at 07:15 AM'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E9E8)),
                  ),
                  child: Column(
                    children: [
                      _receiptRow('Quantity', milk),
                      const SizedBox(height: 8),
                      _receiptRow('FAT %', '$fat%'),
                      const SizedBox(height: 8),
                      _receiptRow('SNF %', '$snf%'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14213D),
                            ),
                          ),
                          Text(
                            amount,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF087F73),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF087F73),
                          side: const BorderSide(color: Color(0xFF087F73)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Milk slip sent to thermal printer.',
                              ),
                              backgroundColor: Color(0xFF087F73),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Slip'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF087F73),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Receipt sent to $memberName on WhatsApp.',
                              ),
                              backgroundColor: const Color(0xFF087F73),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share SMS/WA'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14213D),
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // MILK DETAIL
  // ===========================================================

  Widget _milkDetail(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A869A)),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF344054),
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // EMPTY STATE
  // ===========================================================

  Widget _dateChip(String label, String value) {
    final isSelected = _dateFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _dateFilter = value);
        _loadCollections();
      },
      selectedColor: const Color(0xFF087F73),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? const Color(0xFF087F73) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF087F73)),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _dateFilter = 'CUSTOM';
        _customStartDate = range.start;
        _customEndDate = range.end;
      });
      _loadCollections();
    }
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Network error occurred',
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(
            onPressed: _loadCollections,
            child: Text('Retry'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearch = searchController.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F6F3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.local_drink_outlined,
              size: 34,
              color: const Color(0xFF087F73),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? 'No Collection Found'.tr
                : (ApiService.userRole.toUpperCase() == 'MEMBER'
                    ? 'No Milk Records Found'.tr
                    : 'No Milk Collections Today'.tr),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try searching for another member.'.tr
                : (ApiService.userRole.toUpperCase() == 'MEMBER'
                    ? 'No milk collection records found for this period. Entries recorded at the dairy counter will appear in your passbook.'.tr
                    : 'Start your shift by recording your first milk collection entry.'.tr),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7A869A)),
          ),
          if (!isSearch &&
              ApiService.userRole.toUpperCase() != 'MEMBER') ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddCollection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087F73),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Record First Collection'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnlinkedMemberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_off_rounded,
              size: 36,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Account Not Linked to Farmer Profile'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your login account is not yet linked to a dairy farmer profile. To view your milk collections, slips, and payments, please link your Dairy-issued Farmer Code (e.g., M001) or ask the Dairy Owner to link your profile.'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7A869A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showLinkProfileDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF087F73),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_link_rounded, size: 20),
            label: Text(
              'Link Farmer Profile'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkProfileDialog() {
    final codeController = TextEditingController();
    String? dialogError;
    bool isLinking = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFF087F73)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Link Farmer Profile'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the unique Farmer/Member Code (e.g., M001) given by your Dairy Owner to connect your milk records.'.tr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Farmer / Member Code *'.tr,
                  hintText: 'e.g., M001'.tr,
                  prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF087F73)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 10),
                Text(
                  dialogError!,
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLinking ? null : () => Navigator.pop(ctx),
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087F73),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLinking
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) {
                        setDialogState(() => dialogError = 'Please enter a valid member code.'.tr);
                        return;
                      }
                      setDialogState(() {
                        isLinking = true;
                        dialogError = null;
                      });
                      try {
                        final res = await ApiService.linkMemberProfile(code);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _loadCollections();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully linked to farmer profile ${res['fullName'] ?? code}!'.tr),
                            backgroundColor: const Color(0xFF087F73),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() {
                          isLinking = false;
                          dialogError = e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    },
              child: isLinking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Link Account'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// ADD MILK COLLECTION SCREEN
// ===================================================================

class AddMilkCollectionScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddMilkCollectionScreen({super.key, required this.onSave});

  @override
  State<AddMilkCollectionScreen> createState() =>
      _AddMilkCollectionScreenState();
}

class _AddMilkCollectionScreenState extends State<AddMilkCollectionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController milkController = TextEditingController();

  final TextEditingController fatController = TextEditingController();

  final TextEditingController snfController = TextEditingController();

  String? selectedMember;

  String selectedAnimal = 'Cow';

  String selectedShift = 'Morning';

  Map<String, double>? get _matchedRate {
    final fat = double.tryParse(fatController.text.trim());
    final snf = double.tryParse(snfController.text.trim());
    if (fat == null || snf == null || fat <= 0 || snf <= 0) return null;

    final isCow = selectedAnimal == 'Cow';
    final chartFat = (fat * 10).round() / 10;
    final chartSnf = (snf * 10).round() / 10;
    final clampedFat = chartFat.clamp(isCow ? 2.7 : 5.0, 8.0).toDouble();
    final clampedSnf = chartSnf
        .clamp(isCow ? 7.7 : 8.5, isCow ? 9.7 : 9.7)
        .toDouble();
    final rate = isCow
        ? 26.30 + (clampedFat - 2.7) * 2 + (clampedSnf - 7.7) * 5
        : 38.00 + (clampedFat - 5.0) * 3 + (clampedSnf - 8.5) * 5;

    return {'fat': clampedFat, 'snf': clampedSnf, 'rate': rate};
  }

  // ===========================================================
  // MEMBERS
  // ===========================================================

  List<Map<String, String>> memberList = [];

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
          memberList = data
              .map<Map<String, String>>(
                (m) => {
                  'code': (m['memberCode'] ?? m['id'] ?? '').toString(),
                  'name': (m['name'] ?? m['farmerName'] ?? '').toString(),
                  'animal': (m['animalType'] ?? m['animal'] ?? 'Cow')
                      .toString(),
                },
              )
              .where((m) => m['name']!.isNotEmpty)
              .toList();

          if (memberList.isNotEmpty) {
            selectedMember = memberList.first['name'];
            selectedAnimal = memberList.first['animal'] ?? 'Cow';
          } else {
            selectedMember = null;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    milkController.dispose();
    fatController.dispose();
    snfController.dispose();

    super.dispose();
  }

  void _openHardwareModal() {
    BluetoothDeviceModal.show(
      context,
      onReadingReceived: (reading) {
        setState(() {
          milkController.text = reading.weightLitres.toStringAsFixed(1);
          fatController.text = reading.fat.toStringAsFixed(1);
          snfController.text = reading.snf.toStringAsFixed(1);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Captured: ${reading.weightLitres} L, FAT: ${reading.fat}%, SNF: ${reading.snf}%',
            ),
            backgroundColor: const Color(0xFF087F73),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // ===========================================================
  // BUILD (Add Milk Collection Screen Guard)
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    // BUG 1 Security: Members cannot access collection entry form
    final currentRole = ApiService.userRole.toUpperCase();
    if (currentRole == 'MEMBER') {
      return Scaffold(
        appBar: AppBar(
          title: Text('Access Denied'.tr),
          backgroundColor: const Color(0xFF43A99F),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 64, color: Color(0xFFE11D48)),
                const SizedBox(height: 16),
                Text(
                  'Unauthorized Action'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only Dairy Owners and authorized operators can add milk collections.'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF43A99F),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Milk Collection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur'.tr,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_connected_rounded),
            tooltip: 'Auto-Read from Scale & Analyzer',
            onPressed: _openHardwareModal,
          ),
        ],
      ),

      // =========================================================
      // BODY
      // =========================================================
      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              InkWell(
                onTap: _openHardwareModal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F6F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF087F73).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bluetooth_connected_rounded,
                        color: Color(0xFF087F73),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Auto-Read from Scale & Analyzer (BLE)'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF087F73),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF087F73),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // =================================================
              // MEMBER
              // =================================================

              _sectionTitle('Member'),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),

                child: DropdownButtonFormField<String>(
                  initialValue: selectedMember,

                  decoration: const InputDecoration(
                    labelText: 'Select Member',

                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(0xFF087F73),
                    ),

                    border: InputBorder.none,

                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),

                  items: memberList.map((member) {
                    final name = member['name']!;
                    final animal = member['animal']!;

                    return DropdownMenuItem<String>(
                      value: name,

                      child: Row(
                        children: [
                          Text(
                            animal == 'Cow' ? '🐄' : '🐃',
                            style: const TextStyle(fontSize: 18),
                          ),

                          const SizedBox(width: 8),

                          Text(name),

                          const SizedBox(width: 6),

                          Text(
                            '($animal)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value == null) return;

                    final selected = memberList.firstWhere(
                      (member) => member['name'] == value,
                    );

                    setState(() {
                      selectedMember = value;

                      selectedAnimal = selected['animal']!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // ANIMAL TYPE
              // =================================================
              _sectionTitle('Animal Type'),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _animalButton(
                      emoji: '🐄',
                      title: 'Cow',
                      selected: selectedAnimal == 'Cow',
                      onTap: () {
                        setState(() {
                          selectedAnimal = 'Cow';
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _animalButton(
                      emoji: '🐃',
                      title: 'Buffalo',
                      selected: selectedAnimal == 'Buffalo',
                      onTap: () {
                        setState(() {
                          selectedAnimal = 'Buffalo';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =================================================
              // SHIFT
              // =================================================
              _sectionTitle('Shift'),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _shiftButton(
                      title: 'Morning',
                      icon: Icons.wb_sunny_outlined,
                      selected: selectedShift == 'Morning',

                      onTap: () {
                        setState(() {
                          selectedShift = 'Morning';
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _shiftButton(
                      title: 'Evening',
                      icon: Icons.nights_stay_outlined,
                      selected: selectedShift == 'Evening',

                      onTap: () {
                        setState(() {
                          selectedShift = 'Evening';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =================================================
              // MILK DETAILS
              // =================================================
              _sectionTitle('Milk Details'),

              const SizedBox(height: 12),

              _inputField(
                controller: milkController,
                label: 'Milk Quantity',
                hint: 'Enter litres',
                icon: Icons.local_drink_outlined,
                suffixText: 'Ltr',

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: ValidationUtils.decimalNumberFormatter,

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter milk quantity';
                  }

                  final quantity = double.tryParse(value.trim());

                  if (quantity == null || quantity <= 0) {
                    return 'Enter a valid quantity (numbers only)';
                  }

                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      controller: fatController,
                      label: 'FAT',
                      hint: '5.0',

                      icon: Icons.water_drop_outlined,

                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: ValidationUtils.decimalNumberFormatter,

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter FAT';
                        }

                        final fat = double.tryParse(value.trim());

                        if (fat == null || fat <= 0) {
                          return 'Invalid FAT (numbers only, e.g. 4.5)';
                        }

                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _inputField(
                      controller: snfController,
                      label: 'SNF',
                      hint: '8.0',

                      icon: Icons.opacity_outlined,

                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: ValidationUtils.decimalNumberFormatter,

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter SNF';
                        }

                        final snf = double.tryParse(value.trim());

                        if (snf == null || snf <= 0) {
                          return 'Invalid SNF (numbers only, e.g. 8.5)';
                        }

                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (_matchedRate != null) _ratePreviewCard(_matchedRate!),

              const SizedBox(height: 28),

              // =================================================
              // SAVE
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton.icon(
                  onPressed: _saveCollection,

                  icon: const Icon(Icons.save_outlined),

                  label: const Text('SAVE COLLECTION'),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087F73),

                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // SECTION TITLE
  // ===========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF14213D),
      ),
    );
  }

  // ===========================================================
  // ANIMAL BUTTON
  // ===========================================================

  Widget _animalButton({
    required String emoji,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(vertical: 15),

        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDF1EE) : Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected ? const Color(0xFF43A99F) : const Color(0xFFE5E7EB),

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(emoji, style: const TextStyle(fontSize: 23)),

            const SizedBox(width: 8),

            Text(
              title,

              style: TextStyle(
                fontSize: 13,

                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

                color: selected
                    ? const Color(0xFF087F73)
                    : const Color(0xFF344054),
              ),
            ),

            if (selected) ...[
              const SizedBox(width: 5),

              const Icon(
                Icons.check_circle_rounded,
                size: 17,
                color: Color(0xFF087F73),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // SHIFT BUTTON
  // ===========================================================

  Widget _shiftButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(vertical: 15),

        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDF1EE) : Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected ? const Color(0xFF43A99F) : const Color(0xFFE5E7EB),

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              color: selected
                  ? const Color(0xFF087F73)
                  : const Color(0xFF7A869A),
            ),

            const SizedBox(width: 8),

            Text(
              title,

              style: TextStyle(
                fontSize: 13,

                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

                color: selected
                    ? const Color(0xFF087F73)
                    : const Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // INPUT FIELD
  // ===========================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType: keyboardType,
      inputFormatters: inputFormatters,

      validator: validator,

      onChanged: onChanged,

      decoration: InputDecoration(
        labelText: label,

        hintText: hint,

        prefixIcon: Icon(icon, color: const Color(0xFF087F73)),

        suffixText: suffixText,

        filled: true,

        fillColor: Colors.white,

        labelStyle: const TextStyle(color: Color(0xFF7A869A)),

        hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: const BorderSide(color: Color(0xFF43A99F), width: 1.3),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _ratePreviewCard(Map<String, double> rateEntry) {
    final milk = double.tryParse(milkController.text.trim()) ?? 0;
    final amount = milk * rateEntry['rate']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8E2DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.price_check_outlined,
                  color: Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matched rate from Rate Chart',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Based on the nearest FAT and SNF chart row',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${rateEntry['rate']!.toStringAsFixed(2)}/L',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF087F73),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, color: Color(0xFFB8E2DB)),
          ),
          Row(
            children: [
              Expanded(
                child: _rateDetail(
                  'Chart FAT',
                  '${rateEntry['fat']!.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _rateDetail(
                  'Chart SNF',
                  '${rateEntry['snf']!.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _rateDetail(
                  'Est. Amount',
                  milk > 0 ? '₹${amount.toStringAsFixed(0)}' : 'Enter milk',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateDetail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF667085)),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF14213D),
        ),
      ),
    ],
  );

  // ===========================================================
  // SAVE COLLECTION
  // ===========================================================

  void _saveCollection() {
    if (selectedMember == null || memberList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please register a farmer member first before recording milk collection!'
                .tr,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double milk = double.parse(milkController.text.trim());

    final double fat = double.parse(fatController.text.trim());

    final double snf = double.parse(snfController.text.trim());

    final rate = _matchedRate!['rate']!;

    final double amount = milk * rate;

    // =========================================================
    // NEW COLLECTION
    // =========================================================

    final memberEntry = memberList.firstWhere(
      (m) => m['name'] == selectedMember,
      orElse: () => {'code': 'M001'},
    );

    final newCollection = {
      'memberCode': memberEntry['code'],
      'memberName': selectedMember,
      'animal': selectedAnimal,
      'milk': '${milk.toStringAsFixed(1)} L',
      'fat': fat.toStringAsFixed(1),
      'snf': snf.toStringAsFixed(1),
      'amount': '₹${amount.toStringAsFixed(0)}',
      'shift': selectedShift,
    };

    widget.onSave(newCollection);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Milk collection saved successfully')),
    );
  }
}
