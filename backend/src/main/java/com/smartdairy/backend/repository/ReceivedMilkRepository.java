package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.ReceivedMilk;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReceivedMilkRepository extends MongoRepository<ReceivedMilk, String> {}
