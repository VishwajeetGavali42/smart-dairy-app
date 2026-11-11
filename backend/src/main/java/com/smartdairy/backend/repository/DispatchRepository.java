package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.Dispatch;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DispatchRepository extends MongoRepository<Dispatch, String> {}
