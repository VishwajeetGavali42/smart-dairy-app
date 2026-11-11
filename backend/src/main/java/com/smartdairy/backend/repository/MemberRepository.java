package com.smartdairy.backend.repository;

import com.smartdairy.backend.entity.Member;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MemberRepository extends MongoRepository<Member, String> {
    Optional<Member> findByMemberCode(String memberCode);
    Optional<Member> findByMemberCodeIgnoreCase(String memberCode);
    boolean existsByMemberCodeIgnoreCase(String memberCode);
    List<Member> findByNameContainingIgnoreCaseOrMemberCodeContainingIgnoreCase(String name, String memberCode);
}
