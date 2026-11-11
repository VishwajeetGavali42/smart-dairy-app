import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color secondaryText = Color(0xFF7A869A);
  static const Color background = Color(0xFFF8FAFA);

  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'notif_001',
      'title': 'AI Anomaly Detected',
      'message': 'Unusual FAT level (6.2%) recorded for Ramesh Patil (M001). Higher than standard 4.2%.',
      'time': '10 mins ago',
      'type': 'alert',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFF59E0B),
      'isRead': false,
    },
    {
      'id': 'notif_002',
      'title': 'Tanker Dispatch Scheduled',
      'message': 'Tanker MH-09-CV-4521 scheduled for Chilling Plant dispatch today at 06:30 PM.',
      'time': '45 mins ago',
      'type': 'dispatch',
      'icon': Icons.local_shipping_outlined,
      'color': const Color(0xFF087F73),
      'isRead': false,
    },
    {
      'id': 'notif_003',
      'title': 'Monthly Payouts Settled',
      'message': 'Direct bank transfers of ₹67,230 processed successfully for 5 farmer members.',
      'time': '2 hours ago',
      'type': 'payment',
      'icon': Icons.account_balance_wallet_outlined,
      'color': const Color(0xFF3B82F6),
      'isRead': false,
    },
    {
      'id': 'notif_004',
      'title': 'Cattle Feed Stock Alert',
      'message': 'Kapila Cattle Feed stock is running low (15 bags remaining in center store).',
      'time': 'Yesterday',
      'type': 'alert',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFFEF4444),
      'isRead': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredList {
    if (_selectedFilter == 'All') return _notifications;
    if (_selectedFilter == 'Unread') {
      return _notifications.where((n) => n['isRead'] == false).toList();
    }
    return _notifications
        .where((n) => n['type'] == _selectedFilter.toLowerCase())
        .toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: primary,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((item) => item['isRead'] == false).length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: darkText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            Text(
              '$unreadCount unread alerts',
              style: const TextStyle(fontSize: 11, color: secondaryText),
            ),
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: darkText),
              onSelected: (value) {
                if (value == 'mark_read') _markAllAsRead();
                if (value == 'clear') _clearAll();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'mark_read',
                  child: Text('Mark all as read'),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Text(
                    'Clear all',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // =========================================================
          // FILTER CHIPS
          // =========================================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Unread', 'Alert', 'Payment', 'Dispatch']
                    .map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : secondaryText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // =========================================================
          // LIST
          // =========================================================
          Expanded(
            child: _filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _filteredList[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool isRead = item['isRead'] == true;
    final Color itemColor = item['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? const Color(0xFFE5E9E8)
              : primary.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              item['isRead'] = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: itemColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['message'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: secondaryText.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['time'].toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: secondaryText,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 20),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                item['isRead'] = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Viewing details for: ${item['title']}',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text(
                              'View Detail',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F6F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 34,
              color: primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You are completely caught up!',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }
}
