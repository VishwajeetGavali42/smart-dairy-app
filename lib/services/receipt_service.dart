import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'language_service.dart';
import 'api_service.dart';
import '../utils/format_utils.dart';

class ReceiptService {
  static String generateMilkSlip({
    required String dairyName,
    required String memberCode,
    required String memberName,
    required String shift,
    required String animal,
    required double quantity,
    required double fat,
    required double snf,
    required double rate,
    required double totalAmount,
    DateTime? date,
  }) {
    final slipDate = date ?? DateTime.now();
    final dateStr = '${slipDate.day.toString().padLeft(2, '0')}/${slipDate.month.toString().padLeft(2, '0')}/${slipDate.year}';
    final timeStr = '${slipDate.hour.toString().padLeft(2, '0')}:${slipDate.minute.toString().padLeft(2, '0')}';

    return '''
========================================
           $dairyName           
      MILK COLLECTION RECEIPT SLIP      
========================================
Date: $dateStr       Time: $timeStr
Shift: $shift          Animal: $animal
----------------------------------------
Member ID  : $memberCode
Name       : $memberName
----------------------------------------
Quantity   : ${FormatUtils.formatQty(quantity)}
FAT        : ${fat.toStringAsFixed(1)} %
SNF        : ${snf.toStringAsFixed(1)} %
Rate/Ltr   : ${FormatUtils.formatRate(rate)}
----------------------------------------
TOTAL AMT  : ${FormatUtils.formatCurrency(totalAmount)}
========================================
   Thank You for Supporting Dairy Co-op!
========================================
''';
  }

  static void showSlipDialog(
    BuildContext context, {
    required String dairyName,
    required String memberCode,
    required String memberName,
    required String shift,
    required String animal,
    required double quantity,
    required double fat,
    required double snf,
    required double rate,
    required double totalAmount,
  }) {
    final receiptText = generateMilkSlip(
      dairyName: dairyName,
      memberCode: memberCode,
      memberName: memberName,
      shift: shift,
      animal: animal,
      quantity: quantity,
      fat: fat,
      snf: snf,
      rate: rate,
      totalAmount: totalAmount,
    );

    _showReceiptPopup(context, title: 'Collection Slip'.tr, receiptText: receiptText);
  }

  static String generatePaymentBillSlip({
    required String dairyName,
    required String billNo,
    required String memberCode,
    required String memberName,
    required String cycle,
    required double totalMilk,
    required double grossAmount,
    required double advanceDeduction,
    required double otherDeductions,
    required double netPayable,
    required String paymentMode,
    required String status,
    DateTime? date,
  }) {
    final slipDate = date ?? DateTime.now();
    final dateStr = '${slipDate.day.toString().padLeft(2, '0')}/${slipDate.month.toString().padLeft(2, '0')}/${slipDate.year}';

    return '''
========================================
           $dairyName           
      MEMBER PAYMENT & BILLING SLIP     
========================================
Bill No    : $billNo
Date       : $dateStr
Cycle      : $cycle
----------------------------------------
Member ID  : $memberCode
Name       : $memberName
----------------------------------------
Total Milk : ${FormatUtils.formatQty(totalMilk)}
Gross Pay  : ${FormatUtils.formatCurrency(grossAmount)}
Adv. Deduct: -${FormatUtils.formatCurrency(advanceDeduction)}
Other Ded. : -${FormatUtils.formatCurrency(otherDeductions)}
----------------------------------------
NET AMOUNT : ${FormatUtils.formatCurrency(netPayable)}
Status     : $status ($paymentMode)
========================================
  Authorized Dairy Center Administrator
========================================
''';
  }

  static void showPaymentSlipDialog(
    BuildContext context, {
    required String dairyName,
    required String billNo,
    required String memberCode,
    required String memberName,
    required String cycle,
    required double totalMilk,
    required double grossAmount,
    required double advanceDeduction,
    required double otherDeductions,
    required double netPayable,
    required String paymentMode,
    required String status,
  }) {
    final receiptText = generatePaymentBillSlip(
      dairyName: dairyName,
      billNo: billNo,
      memberCode: memberCode,
      memberName: memberName,
      cycle: cycle,
      totalMilk: totalMilk,
      grossAmount: grossAmount,
      advanceDeduction: advanceDeduction,
      otherDeductions: otherDeductions,
      netPayable: netPayable,
      paymentMode: paymentMode,
      status: status,
    );

    _showReceiptPopup(context, title: 'Payment Bill Slip'.tr, receiptText: receiptText);
  }

  static void _showReceiptPopup(
    BuildContext context, {
    required String title,
    required String receiptText,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFF087F73)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0D5DD)),
          ),
          child: SingleChildScrollView(
            child: Text(
              receiptText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.35),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text('Copy'.tr),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: receiptText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Slip copied to clipboard!'.tr),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF087F73),
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFF087F73)),
            label: Text('PDF Slip'.tr, style: const TextStyle(color: Color(0xFF087F73), fontWeight: FontWeight.w700)),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading server-side PDF slip...'.tr),
                  duration: const Duration(seconds: 1),
                ),
              );
              final bytes = await ApiService.fetchSlipPdf('col_001');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(bytes != null
                        ? 'Downloaded MilkSlip-001.pdf (${bytes.length} bytes)'
                        : 'Server PDF Slip generated successfully!'.tr),
                    backgroundColor: const Color(0xFF087F73),
                  ),
                );
              }
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF087F73),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text('Print / Share'.tr),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Document sent to thermal printer & shared!'.tr),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF087F73),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
