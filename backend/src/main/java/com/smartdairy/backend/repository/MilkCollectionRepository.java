package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.MilkCollection;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface MilkCollectionRepository extends MongoRepository<MilkCollection, String> {
    List<MilkCollection> findByCollectionDate(LocalDate date);
    List<MilkCollection> findByCollectionDateAndShift(LocalDate date, String shift);
    List<MilkCollection> findByMemberCode(String memberCode);
    List<MilkCollection> findByMemberCodeIgnoreCase(String memberCode);
    List<MilkCollection> findByCollectionDateBetween(LocalDate start, LocalDate end);
    List<MilkCollection> findByMemberCodeAndCollectionDateBetween(String memberCode, LocalDate start, LocalDate end);
    List<MilkCollection> findByMemberCodeIgnoreCaseAndCollectionDateBetween(String memberCode, LocalDate start, LocalDate end);
}
