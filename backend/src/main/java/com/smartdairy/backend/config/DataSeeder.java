package com.smartdairy.backend.config;

import com.smartdairy.backend.entity.*;
import com.smartdairy.backend.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Configuration
public class DataSeeder {

    @Bean
    public CommandLineRunner initData(
            UserRepository userRepository,
            MemberRepository memberRepository,
            RateRuleRepository rateRuleRepository,
            MilkCollectionRepository milkCollectionRepository,
            PaymentRepository paymentRepository,
            AdvanceRepository advanceRepository,
            ProductRepository productRepository,
            PasswordEncoder passwordEncoder) {
        return args -> {
            if (userRepository.count() == 0) {
                userRepository.save(new User("owner", passwordEncoder.encode("password"), "Vishwajeet Patil", "+91 98765 43210", RoleType.DAIRY_OWNER));
                userRepository.save(new User("employee", passwordEncoder.encode("password"), "Ramesh Kumar", "+91 98765 43211", RoleType.EMPLOYEE));
                userRepository.save(new User("admin", passwordEncoder.encode("password"), "System Admin", "+91 98765 43213", RoleType.ADMIN));
            }

            if (userRepository.findByUsername("ramesh").isEmpty()) {
                userRepository.save(new User("ramesh", passwordEncoder.encode("password"), "Ramesh Patil", "9876543210", RoleType.MEMBER, "M001"));
            }
            if (userRepository.findByUsername("suresh").isEmpty()) {
                userRepository.save(new User("suresh", passwordEncoder.encode("password"), "Suresh Deshmukh", "9876543211", RoleType.MEMBER, "M002"));
            }
            if (userRepository.findByUsername("anand").isEmpty()) {
                userRepository.save(new User("anand", passwordEncoder.encode("password"), "Anand Shinde", "9876543212", RoleType.MEMBER, "M003"));
            }

            if (rateRuleRepository.count() == 0) {
                rateRuleRepository.save(new RateRule("Cow", 38.0, 3.5, 5.0, 0.40, 8.0, 9.0, 0.30));
                rateRuleRepository.save(new RateRule("Buffalo", 54.0, 6.0, 8.5, 0.60, 8.5, 9.5, 0.40));
            }

            if (memberRepository.count() == 0) {
                Member m1 = new Member("M001", "Ramesh Patil", "9876543210", "Cow", 4.2);
                m1.setTotalMilkSupplied(450.0);
                Member m2 = new Member("M002", "Suresh Deshmukh", "9876543211", "Buffalo", 6.8);
                m2.setTotalMilkSupplied(620.0);
                Member m3 = new Member("M003", "Anand Shinde", "9876543212", "Cow", 4.0);
                m3.setTotalMilkSupplied(380.0);
                Member m4 = new Member("M004", "Prakash Jadhav", "9876543213", "Buffalo", 7.1);
                m4.setTotalMilkSupplied(540.0);
                Member m5 = new Member("M005", "Sunita Kadam", "9876543214", "Cow", 4.3);
                m5.setTotalMilkSupplied(290.0);
                memberRepository.saveAll(List.of(m1, m2, m3, m4, m5));
            }

            if (milkCollectionRepository.count() == 0) {
                MilkCollection c1 = new MilkCollection();
                c1.setMemberCode("M001");
                c1.setMemberName("Ramesh Patil");
                c1.setAnimalType("Cow");
                c1.setShift("Morning");
                c1.setQuantity(15.0);
                c1.setFat(4.2);
                c1.setSnf(8.5);
                c1.setRatePerLitre(40.80);
                c1.setTotalAmount(612.00);
                c1.setCollectionDate(LocalDate.now());

                MilkCollection c2 = new MilkCollection();
                c2.setMemberCode("M002");
                c2.setMemberName("Suresh Deshmukh");
                c2.setAnimalType("Buffalo");
                c2.setShift("Morning");
                c2.setQuantity(20.0);
                c2.setFat(6.8);
                c2.setSnf(9.0);
                c2.setRatePerLitre(58.80);
                c2.setTotalAmount(1176.00);
                c2.setCollectionDate(LocalDate.now());

                MilkCollection c3 = new MilkCollection();
                c3.setMemberCode("M003");
                c3.setMemberName("Anand Shinde");
                c3.setAnimalType("Cow");
                c3.setShift("Morning");
                c3.setQuantity(12.5);
                c3.setFat(4.0);
                c3.setSnf(8.4);
                c3.setRatePerLitre(40.00);
                c3.setTotalAmount(500.00);
                c3.setCollectionDate(LocalDate.now());

                milkCollectionRepository.saveAll(List.of(c1, c2, c3));
            }

            if (paymentRepository.count() == 0) {
                Payment p1 = new Payment();
                p1.setMember("Ramesh Patil");
                p1.setAnimal("Cow");
                p1.setMilk("450.0 L");
                p1.setGross(18360.0);
                p1.setAdvance(2000.0);
                p1.setDeduction(250.0);
                p1.setAmount(16110.0);
                p1.setStatus("Paid");
                p1.setMethod("Bank");
                p1.setCycle("Monthly");
                p1.setDate(LocalDate.now().minusDays(5));

                Payment p2 = new Payment();
                p2.setMember("Suresh Deshmukh");
                p2.setAnimal("Buffalo");
                p2.setMilk("620.0 L");
                p2.setGross(36456.0);
                p2.setAdvance(3500.0);
                p2.setDeduction(400.0);
                p2.setAmount(32556.0);
                p2.setStatus("Paid");
                p2.setMethod("Cash");
                p2.setCycle("Monthly");
                p2.setDate(LocalDate.now().minusDays(5));

                paymentRepository.saveAll(List.of(p1, p2));
            }

            if (advanceRepository.count() == 0) {
                advanceRepository.save(new Advance("Ramesh Patil", "M001", 2000.0, 500.0, "Cattle Feed Advance", "Pending", LocalDate.now().minusDays(10)));
                advanceRepository.save(new Advance("Suresh Deshmukh", "M002", 3500.0, 1000.0, "Festival Advance", "Pending", LocalDate.now().minusDays(12)));
            }

            if (productRepository.count() == 0) {
                productRepository.save(new Product("PROD_001", "Kapila Cattle Feed (50 Kg)", "Cattle Feed", 1450.0, 45, "Bag", "Balanced dairy cattle feed rich in protein & energy for higher milk yield."));
                productRepository.save(new Product("PROD_002", "Chelated Mineral Mixture (1 Kg)", "Supplements", 220.0, 120, "Packet", "Contains essential minerals to boost fertility and immunity in dairy cattle."));
                productRepository.save(new Product("PROD_003", "Calci-Gold Liquid Calcium (5 Ltr)", "Supplements", 850.0, 35, "Can", "High calcium supplement with Vitamin D3 for preventing milk fever."));
                productRepository.save(new Product("PROD_004", "Stainless Steel Milk Can (40 Ltr)", "Equipment", 3200.0, 15, "Piece", "Heavy gauge stainless steel food-grade milk collection can."));
                productRepository.save(new Product("PROD_005", "Teat Dip Antiseptic Solution (1 Ltr)", "Healthcare", 380.0, 60, "Bottle", "Post-milking teat dip for mastitis prevention and udder hygiene."));
            }
        };
    }
}
