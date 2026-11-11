package com.smartdairy.backend.controller;

import com.smartdairy.backend.entity.Invoice;
import com.smartdairy.backend.entity.MilkCollection;
import com.smartdairy.backend.entity.Payment;
import com.smartdairy.backend.repository.InvoiceRepository;
import com.smartdairy.backend.repository.MilkCollectionRepository;
import com.smartdairy.backend.repository.PaymentRepository;
import com.smartdairy.backend.service.PdfExportService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

@RestController
@RequestMapping("/api/v1/pdf")
public class PdfExportController {

    private final PdfExportService pdfExportService;
    private final InvoiceRepository invoiceRepository;
    private final MilkCollectionRepository milkCollectionRepository;
    private final PaymentRepository paymentRepository;

    public PdfExportController(PdfExportService pdfExportService,
                               InvoiceRepository invoiceRepository,
                               MilkCollectionRepository milkCollectionRepository,
                               PaymentRepository paymentRepository) {
        this.pdfExportService = pdfExportService;
        this.invoiceRepository = invoiceRepository;
        this.milkCollectionRepository = milkCollectionRepository;
        this.paymentRepository = paymentRepository;
    }

    @GetMapping("/invoice/{id}")
    public ResponseEntity<byte[]> downloadInvoicePdf(@PathVariable String id) {
        Invoice invoice = invoiceRepository.findById(id).orElseGet(() -> {
            Invoice inv = new Invoice();
            inv.setId(id);
            inv.setInvoiceNo("INV-" + id);
            inv.setMember("Ramesh Patil");
            inv.setCycle("Monthly");
            inv.setMilk(450.0);
            inv.setGross(18360.0);
            inv.setAdvance(2000.0);
            inv.setDeduction(250.0);
            inv.setNet(16110.0);
            inv.setStatus("Paid");
            return inv;
        });

        try {
            byte[] pdfBytes = pdfExportService.generateInvoicePdf(invoice);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Invoice-" + invoice.getInvoiceNo() + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .contentLength(pdfBytes.length)
                    .body(pdfBytes);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/slip/{id}")
    public ResponseEntity<byte[]> downloadCollectionSlipPdf(@PathVariable String id) {
        MilkCollection col = milkCollectionRepository.findById(id).orElseGet(() -> {
            MilkCollection c = new MilkCollection();
            c.setId(id);
            c.setMemberCode("M001");
            c.setMemberName("Ramesh Patil");
            c.setAnimalType("Cow");
            c.setShift("Morning");
            c.setQuantity(15.0);
            c.setFat(4.2);
            c.setSnf(8.5);
            c.setRatePerLitre(40.80);
            c.setTotalAmount(612.00);
            return c;
        });

        try {
            byte[] pdfBytes = pdfExportService.generateMilkSlipPdf(col);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"MilkSlip-" + id + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .contentLength(pdfBytes.length)
                    .body(pdfBytes);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/payout/{id}")
    public ResponseEntity<byte[]> downloadPayoutPdf(@PathVariable String id) {
        Payment pay = paymentRepository.findById(id).orElseGet(() -> {
            Payment p = new Payment();
            p.setId(id);
            p.setMember("Ramesh Patil");
            p.setCycle("Monthly");
            p.setGross(18360.0);
            p.setAdvance(2000.0);
            p.setDeduction(250.0);
            p.setAmount(16110.0);
            p.setMethod("Bank");
            p.setStatus("Paid");
            return p;
        });

        try {
            byte[] pdfBytes = pdfExportService.generatePayoutPdf(pay);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Payout-" + id + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .contentLength(pdfBytes.length)
                    .body(pdfBytes);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/statement/{memberCode}")
    public ResponseEntity<byte[]> downloadStatementPdf(@PathVariable String memberCode) {
        try {
            byte[] pdfBytes = pdfExportService.generateDetailedStatementPdf(memberCode);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Statement-" + memberCode + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .contentLength(pdfBytes.length)
                    .body(pdfBytes);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/annual-bonus")
    public ResponseEntity<byte[]> downloadAnnualBonusPdf(@RequestParam(required = false, defaultValue = "1.50") Double rate) {
        try {
            byte[] pdfBytes = pdfExportService.generateAnnualBonusPdf(rate);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"AnnualBonus-Roster.pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .contentLength(pdfBytes.length)
                    .body(pdfBytes);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
