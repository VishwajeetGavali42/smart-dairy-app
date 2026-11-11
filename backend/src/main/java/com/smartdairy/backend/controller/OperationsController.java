package com.smartdairy.backend.controller;

import com.smartdairy.backend.entity.*;
import com.smartdairy.backend.repository.*;
import com.smartdairy.backend.service.AuditService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/operations")
public class OperationsController {

    private final PaymentRepository paymentRepository;
    private final AdvanceRepository advanceRepository;
    private final DeductionRepository deductionRepository;
    private final InvoiceRepository invoiceRepository;
    private final ExpenseRepository expenseRepository;
    private final DispatchRepository dispatchRepository;
    private final ReceivedMilkRepository receivedMilkRepository;
    private final MilkSaleRepository milkSaleRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    public OperationsController(PaymentRepository paymentRepository, AdvanceRepository advanceRepository,
                                DeductionRepository deductionRepository, InvoiceRepository invoiceRepository,
                                ExpenseRepository expenseRepository, DispatchRepository dispatchRepository,
                                ReceivedMilkRepository receivedMilkRepository, MilkSaleRepository milkSaleRepository,
                                UserRepository userRepository, AuditService auditService) {
        this.paymentRepository = paymentRepository;
        this.advanceRepository = advanceRepository;
        this.deductionRepository = deductionRepository;
        this.invoiceRepository = invoiceRepository;
        this.expenseRepository = expenseRepository;
        this.dispatchRepository = dispatchRepository;
        this.receivedMilkRepository = receivedMilkRepository;
        this.milkSaleRepository = milkSaleRepository;
        this.userRepository = userRepository;
        this.auditService = auditService;
    }

    private Optional<User> getAuthenticatedUser(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) return Optional.empty();
        return userRepository.findByUsername(auth.getName());
    }

    private boolean isMemberRole(Authentication auth) {
        if (auth == null) return false;
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_MEMBER"));
    }

    private String getAuthRole(Authentication auth) {
        if (auth == null || auth.getAuthorities().isEmpty()) return "ROLE_OWNER";
        return auth.getAuthorities().iterator().next().getAuthority();
    }

    // Payments
    @GetMapping("/payments")
    public List<Payment> getPayments(@RequestParam(required = false) String cycle, Authentication auth) {
        if (isMemberRole(auth)) {
            return getMyPayments(auth);
        }
        return cycle != null ? paymentRepository.findByCycle(cycle) : paymentRepository.findAll();
    }

    @GetMapping("/payments/my-payments")
    public List<Payment> getMyPayments(Authentication auth) {
        Optional<User> uOpt = getAuthenticatedUser(auth);
        if (uOpt.isPresent()) {
            User u = uOpt.get();
            String name = u.getFullName();
            String code = u.getMemberCode();
            return paymentRepository.findAll().stream()
                    .filter(p -> (name != null && name.equalsIgnoreCase(p.getMember())) ||
                                 (code != null && code.equalsIgnoreCase(p.getMember())))
                    .toList();
        }
        return Collections.emptyList();
    }

    @PostMapping("/payments")
    public ResponseEntity<?> createPayment(@RequestBody Payment payment, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot disburse payments."));
        }
        if (payment.getGross() == null || payment.getGross() < 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Gross amount cannot be negative."));
        }

        // Server-side strict payment calculation
        double gross = payment.getGross() != null ? payment.getGross() : 0.0;
        double advance = payment.getAdvance() != null ? payment.getAdvance() : 0.0;
        double deductions = payment.getDeduction() != null ? payment.getDeduction() : 0.0;
        double net = Math.max(0.0, Math.round((gross - advance - deductions) * 100.0) / 100.0);
        payment.setAmount(net);

        Payment saved = paymentRepository.save(payment);
        auditService.recordAudit(
                "PAYMENT_DISBURSED",
                "PAYMENT",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Disbursed payment for " + saved.getMember() + ": Gross ₹" + gross + ", Net ₹" + net + " (Cycle: " + saved.getCycle() + ")"
        );
        return ResponseEntity.ok(saved);
    }

    // Advances
    @GetMapping("/advances")
    public List<Advance> getAdvances(Authentication auth) {
        if (isMemberRole(auth)) {
            return getMyAdvances(auth);
        }
        return advanceRepository.findAll();
    }

    @GetMapping("/advances/my-advances")
    public List<Advance> getMyAdvances(Authentication auth) {
        Optional<User> uOpt = getAuthenticatedUser(auth);
        if (uOpt.isPresent()) {
            User u = uOpt.get();
            String name = u.getFullName();
            String code = u.getMemberCode();
            return advanceRepository.findAll().stream()
                    .filter(a -> (name != null && name.equalsIgnoreCase(a.getMember())) ||
                                 (code != null && (code.equalsIgnoreCase(a.getMember()) || code.equalsIgnoreCase(a.getMemberId()))))
                    .toList();
        }
        return Collections.emptyList();
    }

    @PostMapping("/advances")
    public ResponseEntity<?> createAdvance(@RequestBody Advance advance, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot grant advances."));
        }
        if (advance.getAmount() == null || advance.getAmount() <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Advance amount must be greater than zero."));
        }
        if (advance.getRecovered() == null) {
            advance.setRecovered(0.0);
        }
        if (advance.getStatus() == null) {
            advance.setStatus("Active");
        }
        Advance saved = advanceRepository.save(advance);
        auditService.recordAudit(
                "ADVANCE_GRANTED",
                "ADVANCE",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Granted advance of ₹" + saved.getAmount() + " to " + saved.getMember() + " (Reason: " + saved.getReason() + ")"
        );
        return ResponseEntity.ok(saved);
    }

    @PostMapping("/advances/{id}/repay")
    public ResponseEntity<?> recordRepayment(@PathVariable String id, @RequestBody Map<String, Double> payload, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot record repayment directly."));
        }
        Double amount = payload.get("amount");
        if (amount == null || amount <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Repayment amount must be positive."));
        }
        return advanceRepository.findById(id).map(advance -> {
            double currentRecovered = advance.getRecovered() != null ? advance.getRecovered() : 0.0;
            advance.setRecovered(currentRecovered + amount);
            if (advance.getRecovered() >= advance.getAmount()) {
                advance.setStatus("Recovered");
            }
            Advance saved = advanceRepository.save(advance);
            auditService.recordAudit(
                    "ADVANCE_REPAID",
                    "ADVANCE",
                    saved.getId(),
                    auth != null ? auth.getName() : "OWNER",
                    getAuthRole(auth),
                    "Repaid ₹" + amount + " for advance of " + saved.getMember() + ". Total recovered: ₹" + saved.getRecovered()
            );
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    // Deductions
    @GetMapping("/deductions")
    public List<Deduction> getDeductions(Authentication auth) {
        if (isMemberRole(auth)) {
            Optional<User> uOpt = getAuthenticatedUser(auth);
            if (uOpt.isPresent()) {
                String name = uOpt.get().getFullName();
                String code = uOpt.get().getMemberCode();
                return deductionRepository.findAll().stream()
                        .filter(d -> (name != null && name.equalsIgnoreCase(d.getMember())) ||
                                     (code != null && code.equalsIgnoreCase(d.getMember())))
                        .toList();
            }
            return Collections.emptyList();
        }
        return deductionRepository.findAll();
    }

    @PostMapping("/deductions")
    public ResponseEntity<?> createDeduction(@RequestBody Deduction deduction, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot apply deductions."));
        }
        if (deduction.getAmount() == null || deduction.getAmount() <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Deduction amount must be positive."));
        }
        Deduction saved = deductionRepository.save(deduction);
        auditService.recordAudit(
                "DEDUCTION_RECORDED",
                "DEDUCTION",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Applied deduction of ₹" + saved.getAmount() + " to " + saved.getMember() + " for: " + saved.getType()
        );
        return ResponseEntity.ok(saved);
    }

    // Invoices
    @GetMapping("/invoices")
    public List<Invoice> getInvoices(Authentication auth) {
        if (isMemberRole(auth)) {
            return getMyInvoices(auth);
        }
        return invoiceRepository.findAll();
    }

    @GetMapping("/invoices/my-invoices")
    public List<Invoice> getMyInvoices(Authentication auth) {
        Optional<User> uOpt = getAuthenticatedUser(auth);
        if (uOpt.isPresent()) {
            User u = uOpt.get();
            String name = u.getFullName();
            String code = u.getMemberCode();
            return invoiceRepository.findAll().stream()
                    .filter(inv -> (name != null && name.equalsIgnoreCase(inv.getMember())) ||
                                   (code != null && code.equalsIgnoreCase(inv.getMember())))
                    .toList();
        }
        return Collections.emptyList();
    }

    @PostMapping("/invoices")
    public ResponseEntity<?> createInvoice(@RequestBody Invoice invoice, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot generate official invoices."));
        }
        Invoice saved = invoiceRepository.save(invoice);
        auditService.recordAudit(
                "INVOICE_GENERATED",
                "INVOICE",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Generated invoice #" + saved.getId() + " for " + saved.getMember() + " (Cycle: " + saved.getCycle() + ", Net: ₹" + saved.getNet() + ")"
        );
        return ResponseEntity.ok(saved);
    }

    // Expenses - restricted from Members
    @GetMapping("/expenses")
    public ResponseEntity<?> getExpenses(Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members do not have access to operational expenses."));
        }
        return ResponseEntity.ok(expenseRepository.findAll());
    }

    @PostMapping("/expenses")
    public ResponseEntity<?> createExpense(@RequestBody Expense expense, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot record operational expenses."));
        }
        Expense saved = expenseRepository.save(expense);
        auditService.recordAudit(
                "EXPENSE_RECORDED",
                "EXPENSE",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Expense recorded: ₹" + saved.getAmount() + " (" + saved.getCategory() + " - " + saved.getTitle() + ")"
        );
        return ResponseEntity.ok(saved);
    }

    // Logistics (Dispatch & Received) - restricted from Members
    @GetMapping("/dispatches")
    public ResponseEntity<?> getDispatches(Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members do not have access to logistics dispatch data."));
        }
        return ResponseEntity.ok(dispatchRepository.findAll());
    }

    @PostMapping("/dispatches")
    public ResponseEntity<?> createDispatch(@RequestBody Dispatch dispatch, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot record milk dispatches."));
        }
        Dispatch saved = dispatchRepository.save(dispatch);
        auditService.recordAudit(
                "DISPATCH_RECORDED",
                "LOGISTICS",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Dispatch recorded: " + saved.getQuantity() + "L to " + saved.getDestination() + " via vehicle " + saved.getVehicle()
        );
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/received")
    public ResponseEntity<?> getReceived(Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members do not have access to received bulk milk records."));
        }
        return ResponseEntity.ok(receivedMilkRepository.findAll());
    }

    @PostMapping("/received")
    public ResponseEntity<?> createReceived(@RequestBody ReceivedMilk received, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot record received milk."));
        }
        ReceivedMilk saved = receivedMilkRepository.save(received);
        auditService.recordAudit(
                "RECEIVED_RECORDED",
                "LOGISTICS",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Received bulk milk: " + saved.getQuantity() + "L from " + saved.getSource()
        );
        return ResponseEntity.ok(saved);
    }

    // Milk Sales - restricted from Members
    @GetMapping("/milk-sales")
    public ResponseEntity<?> getMilkSales(Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members do not have access to dairy milk sales data."));
        }
        return ResponseEntity.ok(milkSaleRepository.findAll());
    }

    @PostMapping("/milk-sales")
    public ResponseEntity<?> createMilkSale(@RequestBody MilkSale sale, Authentication auth) {
        if (isMemberRole(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Members cannot record milk sales."));
        }
        MilkSale saved = milkSaleRepository.save(sale);
        double totalAmt = (saved.getQuantity() != null && saved.getRate() != null) ? (saved.getQuantity() * saved.getRate()) : 0.0;
        auditService.recordAudit(
                "MILK_SALE_RECORDED",
                "SALE",
                saved.getId(),
                auth != null ? auth.getName() : "OWNER",
                getAuthRole(auth),
                "Milk sale recorded: " + saved.getQuantity() + "L to " + saved.getBuyer() + " @ ₹" + saved.getRate() + "/L = ₹" + totalAmt
        );
        return ResponseEntity.ok(saved);
    }
}
