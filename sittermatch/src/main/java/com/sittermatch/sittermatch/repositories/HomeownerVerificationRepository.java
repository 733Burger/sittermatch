package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface HomeownerVerificationRepository extends JpaRepository<HomeownerVerification, Integer> {

    Optional<HomeownerVerification> findByHomeownerId(Integer homeownerId);

    // Gate check: all three checks approved (no row = not verified)
    default boolean isFullyVerified(Integer homeownerId) {
        return findByHomeownerId(homeownerId)
                .map(HomeownerVerification::isFullyVerified)
                .orElse(false);
    }

    // Admin review queue: anyone with at least one check waiting, oldest first
    @Query("""
            SELECT v FROM HomeownerVerification v
            WHERE v.idStatus = :pending
               OR v.residenceStatus = :pending
               OR v.emergencyStatus = :pending
            ORDER BY v.updatedAt ASC
            """)
    List<HomeownerVerification> findAwaitingReview(@Param("pending") VerificationStatus pending);
}