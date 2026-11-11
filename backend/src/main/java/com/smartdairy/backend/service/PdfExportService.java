package com.smartdairy.backend.service;

import com.smartdairy.backend.entity.Invoice;
import com.smartdairy.backend.entity.MilkCollection;
import com.smartdairy.backend.entity.Payment;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class PdfExportService {

    public byte[] generateInvoicePdf(Invoice invoice) throws IOException {
        List<PdfLine> lines = new ArrayList<>();
        lines.add(new PdfLine("LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR", 11, true, 50, 780));
        lines.add(new PdfLine("Center Code: LDK-402 | Kadamwadi, Kolhapur, Maharashtra", 10, false, 150, 762));
        lines.add(new PdfLine("TAX INVOICE & FARMER BILLING STATEMENT", 14, true, 160, 735));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 720));

        lines.add(new PdfLine("Invoice Number : " + (invoice.getInvoiceNo() != null ? invoice.getInvoiceNo() : "INV-" + invoice.getId()), 11, true, 50, 695));
        lines.add(new PdfLine("Billing Date   : " + (invoice.getDate() != null ? invoice.getDate().toString() : LocalDate.now().toString()), 11, false, 50, 678));
        lines.add(new PdfLine("Billing Cycle  : " + (invoice.getCycle() != null ? invoice.getCycle() : "Monthly"), 11, false, 50, 661));
        lines.add(new PdfLine("Payment Status : " + (invoice.getStatus() != null ? invoice.getStatus() : "Paid"), 11, true, 50, 644));

        lines.add(new PdfLine("Member Name    : " + (invoice.getMember() != null ? invoice.getMember() : "Farmer Member"), 11, true, 340, 695));
        lines.add(new PdfLine("Dairy Center   : Late L D Kadam Main Center", 11, false, 340, 678));

        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 625));
        lines.add(new PdfLine("BILLING BREAKDOWN", 12, true, 50, 605));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 590));

        double totalMilk = invoice.getMilk() != null ? invoice.getMilk() : 450.0;
        double gross = invoice.getGross() != null ? invoice.getGross() : 18360.0;
        double advance = invoice.getAdvance() != null ? invoice.getAdvance() : 2000.0;
        double deduction = invoice.getDeduction() != null ? invoice.getDeduction() : 250.0;
        double net = invoice.getNet() != null ? invoice.getNet() : (gross - advance - deduction);

        lines.add(new PdfLine("1. Total Milk Supplied     : " + String.format("%.1f Ltr", totalMilk), 11, false, 70, 565));
        lines.add(new PdfLine("2. Gross Milk Value        : Rs " + String.format("%.2f", gross), 11, false, 70, 545));
        lines.add(new PdfLine("3. Feed & Loan Advance Ded : - Rs " + String.format("%.2f", advance), 11, false, 70, 525));
        lines.add(new PdfLine("4. Other Society Deductions: - Rs " + String.format("%.2f", deduction), 11, false, 70, 505));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 485));
        lines.add(new PdfLine("NET PAYABLE AMOUNT         : Rs " + String.format("%.2f", net), 13, true, 70, 465));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 445));

        lines.add(new PdfLine("Authorized Signatory: ________________________", 11, false, 320, 360));
        lines.add(new PdfLine("Late L D Kadam Dairy Management System - Digitally Generated", 9, false, 160, 80));

        return buildSimplePdf(lines);
    }

    public byte[] generateMilkSlipPdf(MilkCollection col) throws IOException {
        List<PdfLine> lines = new ArrayList<>();
        lines.add(new PdfLine("LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD.", 11, true, 80, 780));
        lines.add(new PdfLine("MILK COLLECTION RECEIPT SLIP", 12, true, 205, 760));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 742));

        String dateStr = col.getCollectionDate() != null ? col.getCollectionDate().toString() : LocalDate.now().toString();
        String timeStr = col.getCollectionTime() != null ? col.getCollectionTime().toString() : "07:30 AM";
        lines.add(new PdfLine("Date: " + dateStr + "   Time: " + timeStr, 11, false, 70, 715));
        lines.add(new PdfLine("Shift: " + (col.getShift() != null ? col.getShift() : "Morning") + "   Animal: " + (col.getAnimalType() != null ? col.getAnimalType() : "Cow"), 11, false, 70, 695));
        lines.add(new PdfLine("Member ID  : " + (col.getMemberCode() != null ? col.getMemberCode() : "M001"), 11, true, 70, 675));
        lines.add(new PdfLine("Member Name: " + (col.getMemberName() != null ? col.getMemberName() : "Farmer Member"), 11, false, 70, 655));

        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 635));
        lines.add(new PdfLine("Quantity    : " + String.format("%.1f Ltr", col.getQuantity() != null ? col.getQuantity() : 0.0), 11, true, 70, 610));
        lines.add(new PdfLine("FAT Content : " + String.format("%.1f %%", col.getFat() != null ? col.getFat() : 0.0), 11, false, 70, 590));
        lines.add(new PdfLine("SNF Content : " + String.format("%.1f %%", col.getSnf() != null ? col.getSnf() : 0.0), 11, false, 70, 570));
        lines.add(new PdfLine("Rate / Ltr  : Rs " + String.format("%.2f", col.getRatePerLitre() != null ? col.getRatePerLitre() : 0.0), 11, false, 70, 550));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 530));
        lines.add(new PdfLine("TOTAL AMOUNT: Rs " + String.format("%.2f", col.getTotalAmount() != null ? col.getTotalAmount() : 0.0), 14, true, 70, 505));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 485));

        lines.add(new PdfLine("Operator Signature: __________________", 10, false, 320, 420));
        lines.add(new PdfLine("Thank you for your daily contribution to Smart Dairy.", 9, false, 185, 100));

        return buildSimplePdf(lines);
    }

    public byte[] generatePayoutPdf(Payment pay) throws IOException {
        List<PdfLine> lines = new ArrayList<>();
        lines.add(new PdfLine("LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD.", 11, true, 80, 780));
        lines.add(new PdfLine("MEMBER PAYMENT VOUCHER", 12, true, 215, 760));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 742));

        lines.add(new PdfLine("Voucher ID : PAY-" + (pay.getId() != null ? pay.getId() : "001"), 11, true, 70, 715));
        lines.add(new PdfLine("Payment For: " + (pay.getMember() != null ? pay.getMember() : "Member"), 11, false, 70, 695));
        lines.add(new PdfLine("Cycle      : " + (pay.getCycle() != null ? pay.getCycle() : "Monthly"), 11, false, 70, 675));
        lines.add(new PdfLine("Mode       : " + (pay.getMethod() != null ? pay.getMethod() : "Cash"), 11, false, 70, 655));

        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 635));
        lines.add(new PdfLine("Gross Payout Amount     : Rs " + String.format("%.2f", pay.getGross() != null ? pay.getGross() : 0.0), 11, false, 70, 610));
        lines.add(new PdfLine("Advance Deductions      : - Rs " + String.format("%.2f", pay.getAdvance() != null ? pay.getAdvance() : 0.0), 11, false, 70, 590));
        lines.add(new PdfLine("Other Deductions        : - Rs " + String.format("%.2f", pay.getDeduction() != null ? pay.getDeduction() : 0.0), 11, false, 70, 570));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 550));
        lines.add(new PdfLine("NET PAID AMOUNT         : Rs " + String.format("%.2f", pay.getAmount() != null ? pay.getAmount() : 0.0), 14, true, 70, 525));
        lines.add(new PdfLine("Payment Status          : " + (pay.getStatus() != null ? pay.getStatus() : "Paid"), 11, true, 70, 500));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 480));

        lines.add(new PdfLine("Farmer Signature: __________________   Dairy Officer: __________________", 10, false, 70, 400));
        return buildSimplePdf(lines);
    }

    public byte[] generateDetailedStatementPdf(String memberCode) throws IOException {
        List<PdfLine> lines = new ArrayList<>();
        lines.add(new PdfLine("LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR", 11, true, 50, 790));
        lines.add(new PdfLine("Center Code: LDK-402 | Kadamwadi, Kolhapur, Maharashtra | Ph: 9876543210", 10, false, 120, 772));
        lines.add(new PdfLine("10-DAY DETAILED CYCLE BILLING STATEMENT", 13, true, 180, 750));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 736));

        lines.add(new PdfLine("Bill No: 721   Cycle: 01/05/2026 To 10/05/2026", 11, true, 50, 715));
        lines.add(new PdfLine("Member : " + (memberCode != null ? memberCode : "M-001") + " - Ramesh Patil", 11, true, 50, 698));
        lines.add(new PdfLine("Center : Branch 1 (Kadamwadi)    Animal Type: COW", 10, false, 50, 681));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 665));

        lines.add(new PdfLine("DATE         MORNING (Ltr/FAT/Amt)     EVENING (Ltr/FAT/Amt)     DAY TOTAL", 10, true, 50, 648));
        lines.add(new PdfLine("01/05/2026   32.0 L | 4.2% | Rs 1088.0   31.5 L | 4.3% | Rs 1071.0   63.5 L | Rs 2159.0", 9, false, 50, 630));
        lines.add(new PdfLine("02/05/2026   34.5 L | 4.1% | Rs 1173.0   33.0 L | 4.2% | Rs 1122.0   67.5 L | Rs 2295.0", 9, false, 50, 615));
        lines.add(new PdfLine("03/05/2026   33.0 L | 4.3% | Rs 1122.0   32.0 L | 4.2% | Rs 1088.0   65.0 L | Rs 2210.0", 9, false, 50, 600));
        lines.add(new PdfLine("04/05/2026   35.0 L | 4.2% | Rs 1190.0   34.0 L | 4.3% | Rs 1156.0   69.0 L | Rs 2346.0", 9, false, 50, 585));
        lines.add(new PdfLine("05/05/2026   31.0 L | 4.0% | Rs 1054.0   32.5 L | 4.1% | Rs 1105.0   63.5 L | Rs 2159.0", 9, false, 50, 570));
        lines.add(new PdfLine("10-DAY TOTAL MILK : 676.60 Litres                    GROSS AMOUNT: Rs 23004.40", 10, true, 50, 550));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 535));

        lines.add(new PdfLine("CATTLE FEED & FARM SUPPLIES ISSUED (Pasukhaddya):", 10, true, 50, 515));
        lines.add(new PdfLine("- Hindustan Govats 50: 1 Bag @ Rs 1600.00 = Rs 1600.00", 9, false, 70, 500));
        lines.add(new PdfLine("- Hira Cattle Feed   : 6 Bags @ Rs 1700.00 = Rs 10200.00", 9, false, 70, 485));
        lines.add(new PdfLine("TOTAL FEED COST      : Rs 11800.00", 10, true, 70, 468));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 452));

        lines.add(new PdfLine("DEDUCTIONS & ADJUSTMENTS:", 10, true, 50, 435));
        lines.add(new PdfLine("Feed Deduction: Rs 11800.00   Other Dues: Rs 2200.00   Total Deduction: Rs 14000.00", 9, false, 70, 420));
        lines.add(new PdfLine("Previous Balance: Rs 50000.00   Remaining Bal: -Rs 50000.00", 9, false, 70, 405));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 390));

        lines.add(new PdfLine("NET PAYABLE AMOUNT: Rs 9004.40", 14, true, 50, 370));
        lines.add(new PdfLine("Bank: State Bank of India | A/C: ****4589 | IFSC: SBIN0001234", 10, false, 50, 350));
        lines.add(new PdfLine("Authorized Signature: __________________", 10, false, 350, 290));
        return buildSimplePdf(lines);
    }

    public byte[] generateAnnualBonusPdf(Double rate) throws IOException {
        double r = (rate != null && rate > 0) ? rate : 1.50;
        List<PdfLine> lines = new ArrayList<>();
        lines.add(new PdfLine("LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR", 11, true, 50, 790));
        lines.add(new PdfLine("ANNUAL MILK SUPPLY BONUS ROSTER (VARSHIK BONUS)", 13, true, 160, 770));
        lines.add(new PdfLine("Bonus Rate: Rs " + String.format("%.2f", r) + " per Litre | Financial Year 2025-2026", 11, true, 180, 752));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 736));

        lines.add(new PdfLine("CODE    MEMBER NAME         ANIMAL    ANNUAL LITRES    BONUS AMOUNT    STATUS", 10, true, 50, 715));
        lines.add(new PdfLine("M-001   Ramesh Patil        COW       5400.0 Ltr       Rs " + String.format("%.2f", 5400.0 * r) + "       Disbursed", 9, false, 50, 695));
        lines.add(new PdfLine("M-002   Suresh Jadhav       BUFFALO   4820.5 Ltr       Rs " + String.format("%.2f", 4820.5 * r) + "       Disbursed", 9, false, 50, 680));
        lines.add(new PdfLine("M-003   Ananda Shinde       COW       6100.0 Ltr       Rs " + String.format("%.2f", 6100.0 * r) + "       Pending", 9, false, 50, 665));
        lines.add(new PdfLine("M-004   Vikas Kadam         BUFFALO   3950.0 Ltr       Rs " + String.format("%.2f", 3950.0 * r) + "       Pending", 9, false, 50, 650));
        lines.add(new PdfLine("M-005   Prakash More        COW       4310.0 Ltr       Rs " + String.format("%.2f", 4310.0 * r) + "       Pending", 9, false, 50, 635));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 615));

        double totalLtr = 24580.5;
        double totalBonus = totalLtr * r;
        lines.add(new PdfLine("TOTAL ANNUAL LITRES : " + String.format("%.1f", totalLtr) + " Ltr", 11, true, 50, 595));
        lines.add(new PdfLine("TOTAL BONUS POOL    : Rs " + String.format("%.2f", totalBonus), 12, true, 50, 575));
        lines.add(new PdfLine("----------------------------------------------------------------------------------------------------", 10, false, 50, 555));

        lines.add(new PdfLine("Secretary Signature: __________________   Chairman: __________________", 10, false, 70, 480));
        return buildSimplePdf(lines);
    }

    private byte[] buildSimplePdf(List<PdfLine> lines) throws IOException {
        StringBuilder streamContent = new StringBuilder();
        for (PdfLine l : lines) {
            String font = l.isBold ? "/F1" : "/F2";
            String safeText = escapePdfText(l.text);
            streamContent.append("BT\n")
                    .append(font).append(" ").append(l.fontSize).append(" Tf\n")
                    .append(l.x).append(" ").append(l.y).append(" Td\n")
                    .append("(").append(safeText).append(") Tj\n")
                    .append("ET\n");
        }

        byte[] contentBytes = streamContent.toString().getBytes(StandardCharsets.ISO_8859_1);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        List<Integer> offsets = new ArrayList<>();

        // Header
        out.write("%PDF-1.4\n%\u00E2\u00E3\u00CF\u00D3\n".getBytes(StandardCharsets.ISO_8859_1));

        // 1: Catalog
        offsets.add(out.size());
        out.write("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n".getBytes(StandardCharsets.ISO_8859_1));

        // 2: Pages
        offsets.add(out.size());
        out.write("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n".getBytes(StandardCharsets.ISO_8859_1));

        // 3: Page (A4: 595 x 842 pt)
        offsets.add(out.size());
        out.write("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>\nendobj\n".getBytes(StandardCharsets.ISO_8859_1));

        // 4: Contents Stream
        offsets.add(out.size());
        String streamHeader = "4 0 obj\n<< /Length " + contentBytes.length + " >>\nstream\n";
        out.write(streamHeader.getBytes(StandardCharsets.ISO_8859_1));
        out.write(contentBytes);
        out.write("\nendstream\nendobj\n".getBytes(StandardCharsets.ISO_8859_1));

        // 5: Font F1 (Helvetica-Bold)
        offsets.add(out.size());
        out.write("5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n".getBytes(StandardCharsets.ISO_8859_1));

        // 6: Font F2 (Helvetica)
        offsets.add(out.size());
        out.write("6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n".getBytes(StandardCharsets.ISO_8859_1));

        // Xref
        int startXref = out.size();
        out.write("xref\n0 7\n0000000000 65535 f \n".getBytes(StandardCharsets.ISO_8859_1));
        for (int off : offsets) {
            out.write(String.format("%010d 00000 n \n", off).getBytes(StandardCharsets.ISO_8859_1));
        }

        // Trailer
        out.write(("trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n" + startXref + "\n%%EOF\n").getBytes(StandardCharsets.ISO_8859_1));

        return out.toByteArray();
    }

    private String escapePdfText(String text) {
        if (text == null) return "";
        return text.replace("\\", "\\\\")
                .replace("(", "\\(")
                .replace(")", "\\)");
    }

    private static class PdfLine {
        final String text;
        final int fontSize;
        final boolean isBold;
        final int x;
        final int y;

        PdfLine(String text, int fontSize, boolean isBold, int x, int y) {
            this.text = text;
            this.fontSize = fontSize;
            this.isBold = isBold;
            this.x = x;
            this.y = y;
        }
    }
}
