import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pdf_generator_service.dart';

class PdfDownloadDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String fileName,
    required Uint8List pdfBytes,
    String? summaryText,
  }) async {
    // Save to mobile storage (Native Android MediaStore + Local Directory fallback)
    final result = await PdfGeneratorService.savePdfToMobileDevice(
      fileName: fileName,
      pdfBytes: pdfBytes,
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF86EFAC), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF15803D),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              result.success
                  ? 'PDF Saved to Mobile Downloads!'
                  : 'PDF Generated Successfully',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.success
                  ? 'मोबाईलच्या Downloads फोल्डरमध्ये फाइल सेव्ह झाली आहे'
                  : 'PDF तयार झाली आहे',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.fileName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Storage: ${result.isPublicDownload ? 'Downloads (सार्वजनिक डाउनलोड्स)' : 'App Storage'}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Path: ${result.filePath.isNotEmpty ? result.filePath : '/storage/emulated/0/Download/${result.fileName}'}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${(result.fileSize / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF087F73),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Primary Action Row: Open PDF & Share PDF
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF087F73),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 17),
                    label: const Text(
                      'Open PDF',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final opened = await PdfGeneratorService.openPdf(
                        fileName: fileName,
                        pdfBytes: pdfBytes,
                      );
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File saved to Downloads. Open it with any PDF viewer.'),
                            backgroundColor: Color(0xFF087F73),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 17),
                    label: const Text(
                      'Share (शेअर)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await PdfGeneratorService.sharePdf(
                        fileName: fileName,
                        pdfBytes: pdfBytes,
                        summaryText: summaryText,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Secondary Row: Copy Text & Done
            Row(
              children: [
                if (summaryText != null && summaryText.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.copy, size: 15, color: Color(0xFF475569)),
                      label: const Text(
                        'Copy Text',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: summaryText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Slip text copied to clipboard!'),
                            backgroundColor: Color(0xFF087F73),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                if (summaryText != null && summaryText.isNotEmpty)
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Done (पूर्ण)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
