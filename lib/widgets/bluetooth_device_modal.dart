import 'package:flutter/material.dart';
import '../services/hardware_service.dart';
import '../services/language_service.dart';

class BluetoothDeviceModal extends StatefulWidget {
  final Function(HardwareReading reading)? onReadingReceived;

  const BluetoothDeviceModal({super.key, this.onReadingReceived});

  static Future<void> show(BuildContext context, {Function(HardwareReading reading)? onReadingReceived}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BluetoothDeviceModal(onReadingReceived: onReadingReceived),
    );
  }

  @override
  State<BluetoothDeviceModal> createState() => _BluetoothDeviceModalState();
}

class _BluetoothDeviceModalState extends State<BluetoothDeviceModal> {
  bool _isScanning = false;
  HardwareReading? _latestReading;

  void _scanDevices() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  void _fetchTestReading() async {
    final reading = await HardwareIntegrationService.fetchLiveHardwareReading();
    if (mounted) {
      setState(() => _latestReading = reading);
      widget.onReadingReceived?.call(reading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF087F73).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bluetooth_connected_rounded, color: Color(0xFF087F73)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hardware Devices (IoT)'.tr,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF14213D)),
                        ),
                        Text(
                          'Weighing Scale & Milk Analyzer'.tr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isScanning ? null : _scanDevices,
                  icon: _isScanning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: Color(0xFF087F73)),
                  tooltip: 'Scan Devices',
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Paired & Available Devices'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7A869A)),
            ),
            const SizedBox(height: 10),
            ...HardwareIntegrationService.availableDevices.map((dev) {
              final isConnected = (dev.type == DeviceType.weighingScale &&
                      HardwareIntegrationService.connectedScaleName == dev.name) ||
                  (dev.type == DeviceType.milkAnalyzer &&
                      HardwareIntegrationService.connectedAnalyzerName == dev.name);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFE7F6F3) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF087F73) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      dev.type == DeviceType.weighingScale ? Icons.scale_rounded : Icons.science_outlined,
                      color: isConnected ? const Color(0xFF087F73) : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dev.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isConnected ? FontWeight.bold : FontWeight.w500,
                              color: const Color(0xFF14213D),
                            ),
                          ),
                          Text(
                            dev.protocol,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: isConnected ? Colors.red : const Color(0xFF087F73),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isConnected) {
                            HardwareIntegrationService.disconnectDevice(dev.type);
                          } else {
                            HardwareIntegrationService.connectDevice(dev);
                          }
                        });
                      },
                      child: Text(isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E5EA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live Sensor Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        _latestReading != null
                            ? 'Weight: ${_latestReading!.weightLitres}L | FAT: ${_latestReading!.fat}% | SNF: ${_latestReading!.snf}%'
                            : 'Ready to read live parameters',
                        style: TextStyle(
                          fontSize: 12,
                          color: _latestReading != null ? const Color(0xFF087F73) : Colors.grey.shade600,
                          fontWeight: _latestReading != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF087F73),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _fetchTestReading,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Capture', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF087F73)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Done / Close', style: TextStyle(color: Color(0xFF087F73))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
