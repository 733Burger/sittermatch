package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.PetType;
import com.sittermatch.sittermatch.model.ServiceType;
import com.sittermatch.sittermatch.model.Sitter;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SitterRepository extends JpaRepository<Sitter, Integer> {

    // Find sitter by underlying User's email
    Optional<Sitter> findByUserEmail(String email);

    // Find sitters who are verified
    List<Sitter> findByIsVerifiedTrue();

    // Find sitters offering a specific service (searches inside the ElementCollection set)
    List<Sitter> findByServicesContaining(ServiceType serviceType);

    // Find sitters accommodating a specific pet type
    List<Sitter> findByPetPreferencesContaining(PetType petType);

    // Find sitters within a maximum day rate limit
    List<Sitter> findByDayRateLessThanEqual(Double maxDayRate);
}