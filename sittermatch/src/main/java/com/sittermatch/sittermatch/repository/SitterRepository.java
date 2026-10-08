package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Sitter;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SitterRepository extends JpaRepository<Sitter, Integer> {

    // Find sitter by underlying User's email
    Optional<Sitter> findByUserEmail(String email);

    // Find sitters who are verified
    List<Sitter> findByIsVerifiedTrue();

    // Find sitters offering a specific service string
    List<Sitter> findByServiceTypesContaining(String serviceType);

    // Find sitters accommodating a specific pet type string
    List<Sitter> findByPetTypesContaining(String petType);

    // Find sitters within a maximum day rate limit
    List<Sitter> findByDayRateLessThanEqual(Double maxDayRate);
}