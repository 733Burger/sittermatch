package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Homeowner;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface HomeownerRepository extends JpaRepository<Homeowner, Integer> {
    // Find homeowner by the underlying User's email
    Optional<Homeowner> findByUserEmail(String email);

    // Find all homeowners who are verified
    List<Homeowner> findByIsVerifiedTrue();
}
