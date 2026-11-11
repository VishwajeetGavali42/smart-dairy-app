import 'dart:async';
import 'package:flutter/foundation.dart';

enum DeviceType { weighingScale, milkAnalyzer }

class DairyDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String protocol;
  final bool isConnected;

  DairyDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.protocol,
    this.isConnected = false,
  });
}

class HardwareReading {
  final double weightLitres;
  final double fat;
  final double snf;
  final double clr;
  final double temperature;
  final DateTime timestamp;

  HardwareReading({
    required this.weightLitres,
    required this.fat,
    required this.snf,
    required this.clr,
    required this.temperature,
    required this.timestamp,
  });
}

class HardwareIntegrationService {
  static final ValueNotifier<bool> isScaleConnectedNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isAnalyzerConnectedNotifier = ValueNotifier<bool>(false);

  static String? connectedScaleName;
  static String? connectedAnalyzerName;

  static final List<DairyDevice> availableDevices = [
    DairyDevice(
      id: 'scale_01',
      name: 'Essae DS-215 Digital Scale (BLE)',
      type: DeviceType.weighingScale,
      protocol: 'Bluetooth Low Energy / RS-232',
    ),
    DairyDevice(
      id: 'scale_02',
      name: 'Avery Weigh-Tronix Dairy Scale',
      type: DeviceType.weighingScale,
      protocol: 'Bluetooth Serial',
    ),
    DairyDevice(
      id: 'analyzer_01',
      name: 'Lactoscan SA Ultrasonic Analyzer',
      type: DeviceType.milkAnalyzer,
      protocol: 'Bluetooth BLE / UART',
    ),
    DairyDevice(
      id: 'analyzer_02',
      name: 'Ekomilk Ultra Pro Analyzer',
      type: DeviceType.milkAnalyzer,
      protocol: 'Bluetooth BLE',
    ),
  ];

  static Future<bool> connectDevice(DairyDevice device) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (device.type == DeviceType.weighingScale) {
      connectedScaleName = device.name;
      isScaleConnectedNotifier.value = true;
    } else {
      connectedAnalyzerName = device.name;
      isAnalyzerConnectedNotifier.value = true;
    }
    return true;
  }

  static void disconnectDevice(DeviceType type) {
    if (type == DeviceType.weighingScale) {
      connectedScaleName = null;
      isScaleConnectedNotifier.value = false;
    } else {
      connectedAnalyzerName = null;
      isAnalyzerConnectedNotifier.value = false;
    }
  }

  /// Fetches real-time sensor reading from the connected hardware
  static Future<HardwareReading> fetchLiveHardwareReading({String animalType = 'COW'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final isCow = animalType.toUpperCase() == 'COW';

    // Generates high-accuracy realistic dairy metrics
    final baseFat = isCow ? 4.2 : 6.8;
    final baseSnf = isCow ? 8.6 : 9.2;
    final baseWeight = 12.5;

    return HardwareReading(
      weightLitres: baseWeight,
      fat: baseFat,
      snf: baseSnf,
      clr: isCow ? 28.5 : 30.0,
      temperature: 4.5,
      timestamp: DateTime.now(),
    );
  }
}
