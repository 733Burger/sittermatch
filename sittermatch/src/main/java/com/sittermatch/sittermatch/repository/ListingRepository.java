package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Listing;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ListingRepository extends JpaRepository<Listing, Integer> {

    // Find all listings posted by a specific homeowner
    List<Listing> findByHomeownerId(Integer homeownerId);

    // Find listings by status (e.g., "OPEN", "BOOKED", "COMPLETED")
    List<Listing> findByStatus(String status);

    // Find active listings in a specific suburb
    List<Listing> findBySuburbAndStatus(String suburb, String status);
}
