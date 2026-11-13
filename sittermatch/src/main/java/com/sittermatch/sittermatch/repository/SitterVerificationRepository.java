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

    // How many of the three checks have been filled in, counted the same way as for homeowners.
    @Query(
    value = "SELECT "
        + "(CASE WHEN id_photo IS NOT NULL THEN 1 ELSE 0 END) "
        + "+ (CASE WHEN residence_address IS NOT NULL AND residence_address <> '' THEN 1 ELSE 0 END) "
        + "+ (CASE WHEN emergency_contact_name IS NOT NULL AND emergency_contact_name <> '' "
        + "AND emergency_contact_phone_number IS NOT NULL AND emergency_contact_phone_number <> '' THEN 1 ELSE 0 END) "
        + "FROM sitter_verifications "
        + "WHERE sitter_id = :sitterId",
    nativeQuery = true
    )
    Integer countVerificationSections(@Param("sitterId") Integer sitterId);
}