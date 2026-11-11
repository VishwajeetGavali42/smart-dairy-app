package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.Payment;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaymentRepository extends MongoRepository<Payment, String> {
    List<Payment> findByCycle(String cycle);
    List<Payment> findByStatus(String status);
}
