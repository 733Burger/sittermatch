package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface HomeownerVerificationRepository extends JpaRepository<HomeownerVerification, Integer> {

    Optional<HomeownerVerification> findByHomeownerId(Integer homeownerId);

    // default boolean isFullyVerified(Integer homeownerId) {
    //     return findByHomeownerId(homeownerId)
    //             .map(HomeownerVerification::isApproved)
    //             .orElse(false);
    // }

    @Query("SELECT v FROM HomeownerVerification v"
        + " WHERE v.idStatus = :pending "
        + " OR v.residenceStatus = :pending "
        + " OR v.emergencyStatus = :pending "
        + " ORDER BY v.updatedAt ASC")
    List<HomeownerVerification> findAwaitingReview(@Param("pending") VerificationStatus pending);

    @Query(
    value = "SELECT "
        + "(CASE WHEN id_photo IS NOT NULL THEN 1 ELSE 0 END) "
        + "+ (CASE WHEN residence_address IS NOT NULL AND residence_address <> '' THEN 1 ELSE 0 END) "
        + "+ (CASE WHEN emergency_contact_name IS NOT NULL AND emergency_contact_name <> '' "
        + "AND emergency_contact_phone_number IS NOT NULL AND emergency_contact_phone_number <> '' THEN 1 ELSE 0 END) "
        + "FROM homeowner_verifications "
        + "WHERE homeowner_id = :homeownerId",
    nativeQuery = true
    )
    Integer countVerificationSections(@Param("homeownerId") Integer homeownerId);
}