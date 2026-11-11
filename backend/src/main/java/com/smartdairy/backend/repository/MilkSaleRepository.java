package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.MilkSale;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MilkSaleRepository extends MongoRepository<MilkSale, String> {}
