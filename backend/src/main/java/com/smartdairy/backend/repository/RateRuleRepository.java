package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.RateRule;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface RateRuleRepository extends MongoRepository<RateRule, String> {
    Optional<RateRule> findByAnimalTypeIgnoreCase(String animalType);
}
