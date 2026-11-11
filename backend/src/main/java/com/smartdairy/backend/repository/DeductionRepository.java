package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.Deduction;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DeductionRepository extends MongoRepository<Deduction, String> {
    List<Deduction> findByMember(String member);
}
