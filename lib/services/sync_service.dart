import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SyncItem {
  final String id;
  final String type; // 'collection', 'member', 'advance', 'expense', etc.
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SyncItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
        id: json['id'],
        type: json['type'],
        payload: Map<String, dynamic>.from(json['payload']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SyncService {
  static final List<SyncItem> _queue = [];
  static final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  static int get pendingCount => _queue.length;

  static void enqueue(String type, Map<String, dynamic> payload) {
    final item = SyncItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    _queue.add(item);
    pendingCountNotifier.value = _queue.length;
  }

  static Future<int> syncAll() async {
    if (_queue.isEmpty || isSyncingNotifier.value) return 0;

    isSyncingNotifier.value = true;
    int syncedCount = 0;
    final List<SyncItem> failed = [];

    for (final item in List<SyncItem>.from(_queue)) {
      bool success = false;
      try {
        switch (item.type) {
          case 'collection':
            final res = await ApiService.recordCollection(item.payload);
            success = res != null;
            break;
          case 'member':
            final res = await ApiService.addMember(item.payload);
            success = res != null;
            break;
          case 'advance':
            final res = await ApiService.createAdvance(item.payload);
            success = res != null;
            break;
          case 'expense':
            final res = await ApiService.createExpense(item.payload);
            success = res != null;
            break;
          case 'dispatch':
            final res = await ApiService.createDispatch(item.payload);
            success = res != null;
            break;
          case 'payment':
            final res = await ApiService.createPayment(item.payload);
            success = res != null;
            break;
          case 'invoice':
            final res = await ApiService.createInvoice(item.payload);
            success = res != null;
            break;
          case 'deduction':
            final res = await ApiService.createDeduction(item.payload);
            success = res != null;
            break;
          case 'milk_sale':
            final res = await ApiService.createMilkSale(item.payload);
            success = res != null;
            break;
          case 'received':
            final res = await ApiService.createReceived(item.payload);
            success = res != null;
            break;
          default:
            success = true;
        }
      } catch (_) {
        success = false;
      }

      if (success) {
        syncedCount++;
      } else {
        failed.add(item);
      }
    }

    _queue.clear();
    _queue.addAll(failed);
    pendingCountNotifier.value = _queue.length;
    isSyncingNotifier.value = false;

    return syncedCount;
  }
}
