package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.SitterVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SitterVerificationRepository extends JpaRepository<SitterVerification, Integer> {

    Optional<SitterVerification> findBySitterId(Integer sitterId);

    // Sitters who have at least one check with the given status (used for the admin's pending list).
    @Query("SELECT v FROM SitterVerification v "
            + "WHERE v.idStatus = :status "
            + "OR v.residenceStatus = :status "
            + "OR v.emergencyStatus = :status")
    List<SitterVerification> findAwaitingReview(@Param("status") VerificationStatus status);

    @Query("SELECT " +
           "(CASE WHEN v.idStatus = 'APPROVED' THEN 1 ELSE 0 END) + " +
           "(CASE WHEN v.residenceStatus = 'APPROVED' THEN 1 ELSE 0 END) + " +
           "(CASE WHEN v.emergencyStatus = 'APPROVED' THEN 1 ELSE 0 END) " +
           "FROM SitterVerification v WHERE v.sitter.id = :sitterId")
    Integer countVerificationSections(@Param("sitterId") Integer sitterId);
}