package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.Advance;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AdvanceRepository extends MongoRepository<Advance, String> {
    List<Advance> findByMemberId(String memberId);
    List<Advance> findByStatus(String status);
}
