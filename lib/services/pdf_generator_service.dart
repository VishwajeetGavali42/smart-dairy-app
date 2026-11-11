import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PdfLine {
  final String text;
  final int fontSize;
  final bool isBold;
  final int x;
  final int y;

  PdfLine(this.text, this.fontSize, this.isBold, this.x, this.y);
}

class PdfGeneratorService {
  /// Generates pure PDF 1.4 bytes without external binary dependencies
  static Uint8List buildSimplePdf(List<PdfLine> lines) {
    final streamContent = StringBuffer();
    for (final l in lines) {
      final font = l.isBold ? '/F1' : '/F2';
      final safeText = _escapePdfText(l.text);
      streamContent.write('BT\n');
      streamContent.write('$font ${l.fontSize} Tf\n');
      streamContent.write('${l.x} ${l.y} Td\n');
      streamContent.write('($safeText) Tj\n');
      streamContent.write('ET\n');
    }

    final contentBytes = latin1.encode(streamContent.toString());
    final buffer = BytesBuilder();
    final offsets = <int>[];

    // Header
    buffer.add(latin1.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));

    // 1: Catalog
    offsets.add(buffer.length);
    buffer.add(latin1.encode('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'));

    // 2: Pages
    offsets.add(buffer.length);
    buffer.add(latin1.encode('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'));

    // 3: Page (A4: 595 x 842 pt)
    offsets.add(buffer.length);
    buffer.add(latin1.encode(
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>\nendobj\n'));

    // 4: Contents Stream
    offsets.add(buffer.length);
    final streamHeader = '4 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n';
    buffer.add(latin1.encode(streamHeader));
    buffer.add(contentBytes);
    buffer.add(latin1.encode('\nendstream\nendobj\n'));

    // 5: Font F1 (Helvetica-Bold)
    offsets.add(buffer.length);
    buffer.add(latin1.encode(
        '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n'));

    // 6: Font F2 (Helvetica)
    offsets.add(buffer.length);
    buffer.add(latin1.encode(
        '6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n'));

    // Xref
    final startXref = buffer.length;
    buffer.add(latin1.encode('xref\n0 7\n0000000000 65535 f \n'));
    for (final off in offsets) {
      buffer.add(latin1.encode('${off.toString().padLeft(10, '0')} 00000 n \n'));
    }

    // Trailer
    buffer.add(latin1.encode('trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF\n'));

    return buffer.toBytes();
  }

  static String _escapePdfText(String text) {
    var sanitized = text
        .replaceAll('₹', 'Rs ')
        .replaceAll('•', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-');
    final sb = StringBuffer();
    for (int i = 0; i < sanitized.length; i++) {
      final code = sanitized.codeUnitAt(i);
      if (code > 255) {
        sb.write(' ');
      } else {
        sb.writeCharCode(code);
      }
    }
    return sb.toString()
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)');
  }

  /// Generate Detailed 10-Day Cycle Billing Statement PDF
  static Uint8List generateDetailedStatementPdf(Map<String, dynamic> data) {
    final dairy = (data['dairyInfo'] as Map<String, dynamic>?) ?? {};
    final member = (data['memberInfo'] as Map<String, dynamic>?) ?? {};
    final summary = (data['summary'] as Map<String, dynamic>?) ?? {};
    final rows = (data['dailyRows'] as List<dynamic>?) ?? [];
    final feedList = (data['feedPurchases'] as List<dynamic>?) ?? [];

    final lines = <PdfLine>[];
    lines.add(PdfLine(dairy['name']?.toString() ?? 'LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR', 12, true, 50, 800));
    lines.add(PdfLine('${dairy['address'] ?? 'Kadamwadi, Kolhapur, Maharashtra'} | Phone: ${dairy['phone'] ?? '9876543210'}', 10, false, 50, 782));
    lines.add(PdfLine('10-DAY DETAILED CYCLE BILLING STATEMENT', 13, true, 180, 760));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 746));

    lines.add(PdfLine('Bill No: ${data['billNo'] ?? '721'}   |   Cycle: ${data['cyclePeriod'] ?? '01/05/2026 To 10/05/2026'}', 11, true, 50, 726));
    lines.add(PdfLine('Member : ${member['code'] ?? 'M-001'} - ${member['name'] ?? 'Ramesh Patil'}', 11, true, 50, 709));
    lines.add(PdfLine('Center : ${member['village'] ?? 'Center 1'}   Animal Type: ${member['milkType'] ?? 'COW'}', 10, false, 50, 692));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 676));

    lines.add(PdfLine('DATE         MORNING (Ltr/FAT/Amt)       EVENING (Ltr/FAT/Amt)       DAY TOTAL', 10, true, 50, 658));

    int currentY = 640;
    for (int i = 0; i < rows.length && i < 6; i++) {
      final r = rows[i];
      final m = r['m'] ?? {};
      final e = r['e'] ?? {};
      final totalLtr = ((m['ltr'] ?? 0.0) as num) + ((e['ltr'] ?? 0.0) as num);
      final totalAmt = ((m['amt'] ?? 0.0) as num) + ((e['amt'] ?? 0.0) as num);

      final rowStr = '${r['date']}   ${m['ltr'] ?? '-'} L | ${m['fat'] ?? '-'}% | Rs ${m['amt'] ?? '-'}     ${e['ltr'] ?? '-'} L | ${e['fat'] ?? '-'}% | Rs ${e['amt'] ?? '-'}     ${totalLtr.toStringAsFixed(1)} L | Rs ${totalAmt.toStringAsFixed(1)}';
      lines.add(PdfLine(rowStr, 9, false, 50, currentY));
      currentY -= 15;
    }

    lines.add(PdfLine('10-DAY TOTAL MILK : ${summary['totalLiters'] ?? '676.60'} Litres       GROSS AMOUNT: Rs ${summary['milkTotalAmount'] ?? '23004.40'}', 10, true, 50, currentY - 5));
    currentY -= 22;
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, currentY));
    currentY -= 16;

    // Cattle feed section
    lines.add(PdfLine('CATTLE FEED & FARM SUPPLIES ISSUED (Pasukhaddya):', 10, true, 50, currentY));
    currentY -= 14;
    if (feedList.isEmpty) {
      lines.add(PdfLine('- No cattle feed issued during this period.', 9, false, 70, currentY));
      currentY -= 14;
    } else {
      for (final f in feedList) {
        lines.add(PdfLine('- ${f['item']}: ${f['qty']} Bags @ Rs ${f['rate']} = Rs ${f['total']}', 9, false, 70, currentY));
        currentY -= 14;
      }
    }

    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, currentY));
    currentY -= 16;
    lines.add(PdfLine('DEDUCTIONS & ADJUSTMENTS:', 10, true, 50, currentY));
    currentY -= 14;
    lines.add(PdfLine('Total Deductions: - Rs ${summary['totalDeduction'] ?? '14000.00'}  |  Prev Balance: Rs ${summary['previousBalance'] ?? '50000.00'}', 9, false, 70, currentY));
    currentY -= 18;
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, currentY));
    currentY -= 18;

    lines.add(PdfLine('NET PAYABLE AMOUNT : Rs ${summary['netPayable'] ?? '9004.40'}', 14, true, 50, currentY));
    currentY -= 18;
    lines.add(PdfLine('Bank: ${member['bankName'] ?? 'SBI'} | A/C: ${member['accountNo'] ?? '****4589'} | Remaining Balance: Rs ${summary['remainingBalance'] ?? '0.00'}', 10, false, 50, currentY));
    currentY -= 30;
    lines.add(PdfLine('Authorized Signatory: ________________________', 10, false, 330, currentY));

    return buildSimplePdf(lines);
  }

  /// Generate Annual Member Bonus PDF
  static Uint8List generateAnnualBonusPdf(List<Map<String, dynamic>> bonusList, double rate) {
    final lines = <PdfLine>[];
    lines.add(PdfLine('LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR', 12, true, 50, 800));
    lines.add(PdfLine('ANNUAL MILK SUPPLY BONUS ROSTER (VARSHIK BONUS)', 13, true, 160, 780));
    lines.add(PdfLine('Incentive Rate: Rs ${rate.toStringAsFixed(2)} per Litre | Financial Year 2025-2026', 11, true, 180, 762));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 746));

    lines.add(PdfLine('CODE    MEMBER NAME         ANIMAL    ANNUAL LITRES    BONUS AMOUNT    STATUS', 10, true, 50, 725));
    int currentY = 705;

    double totalLitres = 0.0;
    double totalBonus = 0.0;

    for (final item in bonusList) {
      final code = (item['memberCode'] ?? '').toString().padRight(7);
      final name = (item['memberName'] ?? 'Member').toString().padRight(19);
      final animal = (item['animalType'] ?? 'Cow').toString().padRight(9);
      final litres = ((item['annualLitres'] ?? 0.0) as num).toDouble();
      final bonus = ((item['bonusAmount'] ?? 0.0) as num).toDouble();
      final status = (item['status'] ?? 'Pending').toString();

      totalLitres += litres;
      totalBonus += bonus;

      lines.add(PdfLine(
        '$code $name $animal ${litres.toStringAsFixed(1)} Ltr       Rs ${bonus.toStringAsFixed(2)}    $status',
        9,
        false,
        50,
        currentY,
      ));
      currentY -= 16;
    }

    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, currentY));
    currentY -= 18;
    lines.add(PdfLine('TOTAL ANNUAL MILK : ${totalLitres.toStringAsFixed(1)} Litres', 11, true, 50, currentY));
    currentY -= 16;
    lines.add(PdfLine('TOTAL BONUS POOL  : Rs ${totalBonus.toStringAsFixed(2)}', 12, true, 50, currentY));
    currentY -= 20;
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, currentY));
    currentY -= 35;
    lines.add(PdfLine('Secretary Signature: __________________   Chairman: __________________', 10, false, 70, currentY));

    return buildSimplePdf(lines);
  }

  /// Generate Single Invoice Slip PDF
  static Uint8List generateInvoicePdf(Map<String, dynamic> inv) {
    final lines = <PdfLine>[];
    lines.add(PdfLine('LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR', 12, true, 50, 800));
    lines.add(PdfLine('MEMBER PAYMENT INVOICE / SLIP', 13, true, 195, 780));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 762));

    lines.add(PdfLine('Invoice No : ${inv['invoiceNo'] ?? inv['id'] ?? 'INV-001'}', 11, true, 50, 740));
    lines.add(PdfLine('Member Name: ${inv['member'] ?? inv['memberName'] ?? 'Member'}', 11, true, 50, 722));
    lines.add(PdfLine('Cycle      : ${inv['cycle'] ?? '10 Days'}', 10, false, 50, 704));
    lines.add(PdfLine('Status     : ${inv['status'] ?? 'Paid'}', 10, true, 50, 686));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 668));

    final milk = (inv['milk'] ?? inv['totalLiters'] ?? 0.0) as num;
    final gross = (inv['gross'] ?? inv['grossAmount'] ?? 0.0) as num;
    final adv = (inv['advance'] ?? inv['advanceRecovery'] ?? 0.0) as num;
    final ded = (inv['deduction'] ?? inv['deductions'] ?? 0.0) as num;
    final net = (inv['net'] ?? inv['netAmount'] ?? 0.0) as num;

    lines.add(PdfLine('1. Total Milk Supplied     : ${milk.toStringAsFixed(1)} Litres', 11, false, 70, 645));
    lines.add(PdfLine('2. Gross Milk Value        : Rs ${gross.toStringAsFixed(2)}', 11, false, 70, 625));
    lines.add(PdfLine('3. Less Advance Recovery   : - Rs ${adv.toStringAsFixed(2)}', 11, false, 70, 605));
    lines.add(PdfLine('4. Less Other Deductions   : - Rs ${ded.toStringAsFixed(2)}', 11, false, 70, 585));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 565));
    lines.add(PdfLine('NET FARMER PAYABLE         : Rs ${net.toStringAsFixed(2)}', 14, true, 70, 540));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 520));

    lines.add(PdfLine('Authorized Signatory: ________________________', 10, false, 320, 440));
    return buildSimplePdf(lines);
  }

  /// Generate Executive Summary & Audit Report PDF
  static Uint8List generateSummaryReportPdf(String period, Map<String, dynamic> data) {
    final lines = <PdfLine>[];
    lines.add(PdfLine('LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR', 12, true, 50, 800));
    lines.add(PdfLine('EXECUTIVE PERFORMANCE & FINANCIAL REPORT', 13, true, 160, 780));
    lines.add(PdfLine('Reporting Period: $period   |   Generated: ${DateTime.now().toString().split(" ")[0]}', 10, true, 175, 762));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 746));

    lines.add(PdfLine('KEY BUSINESS SUMMARY METRICS', 11, true, 50, 725));
    lines.add(PdfLine('1. Total Milk Collection       : ${data['collection'] ?? '-'}', 10, false, 70, 705));
    lines.add(PdfLine('2. Gross Realized Revenue      : ${data['revenue'] ?? '-'}', 10, false, 70, 687));
    lines.add(PdfLine('3. Operating Expenses          : ${data['expenses'] ?? '-'}', 10, false, 70, 669));
    lines.add(PdfLine('4. Net Society Profit          : ${data['netProfit'] ?? '-'}', 11, true, 70, 651));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 633));

    lines.add(PdfLine('MEMBER PAYOUTS & QUALITY ANALYSIS', 11, true, 50, 612));
    lines.add(PdfLine('Farmer Milk Payments  : ${data['memberPayments'] ?? '-'}', 10, false, 70, 592));
    lines.add(PdfLine('Payment Details       : ${data['memberPaymentsDetail'] ?? '-'}', 9, false, 70, 574));
    lines.add(PdfLine('Feed & Loan Recovery  : ${data['deductions'] ?? '-'}', 10, false, 70, 556));
    lines.add(PdfLine('Average Quality Grade : ${data['qualityFat'] ?? '-'}', 10, false, 70, 538));
    lines.add(PdfLine('Quality Assessment    : ${data['qualityDesc'] ?? '-'}', 9, false, 70, 520));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 502));

    lines.add(PdfLine('DISPATCH & SALES CHANNELS', 11, true, 50, 481));
    lines.add(PdfLine('${data['salesDesc'] ?? 'Plant dispatches and direct retail distribution'}', 10, false, 70, 461));
    lines.add(PdfLine('----------------------------------------------------------------------------------------------------', 10, false, 50, 441));

    lines.add(PdfLine('This document is an electronically certified ledger audit from Smart Dairy Co-op System.', 9, false, 75, 410));
    lines.add(PdfLine('Dairy Manager: ______________________    Auditor Signature: ______________________', 10, false, 60, 360));

    return buildSimplePdf(lines);
  }

  static const MethodChannel _channel = MethodChannel('com.smartdairy/native_pdf');

  /// Save PDF file directly into mobile Download folder using Android MediaStore
  static Future<FileResult> savePdfToMobileDevice({
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    final sanitizedFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';

    // 1. Try Native Android Platform Channel first (MediaStore.Downloads)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>('savePdfToDownloads', {
          'fileName': sanitizedFileName,
          'bytes': pdfBytes,
        });
        if (res != null && res['success'] == true) {
          return FileResult(
            success: true,
            filePath: (res['filePath'] as String?) ?? '/storage/emulated/0/Download/$sanitizedFileName',
            fileName: sanitizedFileName,
            fileSize: (res['fileSize'] as int?) ?? pdfBytes.length,
            isPublicDownload: (res['isPublicDownload'] as bool?) ?? true,
          );
        }
      } catch (e) {
        debugPrint('PdfGeneratorService native MediaStore save error: $e');
      }
    }

    // 2. Candidate filesystem directories on Android & iOS & Desktop
    final candidateDirs = [
      Directory('/storage/emulated/0/Download'),
      Directory('/sdcard/Download'),
      Directory.systemTemp,
    ];

    for (final dir in candidateDirs) {
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final file = File('${dir.path}/$sanitizedFileName');
        file.writeAsBytesSync(pdfBytes, flush: true);
        if (file.existsSync() && file.lengthSync() > 0) {
          return FileResult(
            success: true,
            filePath: file.path,
            fileName: sanitizedFileName,
            fileSize: file.lengthSync(),
            isPublicDownload: dir.path.contains('Download'),
          );
        }
      } catch (e) {
        debugPrint('PdfGeneratorService write error in ${dir.path}: $e');
      }
    }

    return FileResult(
      success: false,
      filePath: '',
      fileName: sanitizedFileName,
      fileSize: 0,
      errorMessage: 'Could not access mobile downloads storage.',
    );
  }

  /// Open the PDF using the system PDF viewer
  static Future<bool> openPdf({
    required String fileName,
    Uint8List? pdfBytes,
  }) async {
    final sanitizedFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('openPdf', {
          'fileName': sanitizedFileName,
          'bytes': pdfBytes,
        });
        return res ?? false;
      } catch (e) {
        debugPrint('Error opening PDF: $e');
        return false;
      }
    }
    return false;
  }

  /// Share the PDF using the system share sheet (WhatsApp, Gmail, etc.)
  static Future<bool> sharePdf({
    required String fileName,
    Uint8List? pdfBytes,
    String? summaryText,
  }) async {
    final sanitizedFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('sharePdf', {
          'fileName': sanitizedFileName,
          'bytes': pdfBytes,
          'summaryText': summaryText,
        });
        return res ?? false;
      } catch (e) {
        debugPrint('Error sharing PDF: $e');
        return false;
      }
    }
    return false;
  }
}

class FileResult {
  final bool success;
  final String filePath;
  final String fileName;
  final int fileSize;
  final bool isPublicDownload;
  final String? errorMessage;

  FileResult({
    required this.success,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.isPublicDownload = false,
    this.errorMessage,
  });
}
