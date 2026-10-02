package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.HomeownerVerification;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;


public interface HomeownerVerificationRepository extends JpaRepository<HomeownerVerification, Integer> {

    Optional<HomeownerVerification> findByHomeownerId(Integer homeownerId);
    
    // Duplicate check: has this SA ID already been used on another account?
    boolean existsByIdNumberHash(String idNumberHash);

    // Gate check: is this homeowner approved? (listings, bookings)
    boolean existsByHomeownerIdAndStatus(Integer homeownerId, String status);

    // Admin review queue, oldest submissions first
    List<HomeownerVerification> findByStatusOrderBySubmittedAtAsc(String status);
}