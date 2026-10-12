package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.SitterVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface SitterVerificationRepository extends JpaRepository<SitterVerification, Integer> {
    
    Optional<SitterVerification> findBySitterId(Integer sitterId);

    @Query("SELECT " +
           "(CASE WHEN v.idStatus = 'APPROVED' THEN 1 ELSE 0 END) + " +
           "(CASE WHEN v.residenceStatus = 'APPROVED' THEN 1 ELSE 0 END) + " +
           "(CASE WHEN v.emergencyStatus = 'APPROVED' THEN 1 ELSE 0 END) " +
           "FROM SitterVerification v WHERE v.sitter.id = :sitterId")
    Integer countVerificationSections(@Param("sitterId") Integer sitterId);
}