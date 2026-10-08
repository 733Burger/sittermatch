package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;


import java.util.List;


public interface ReviewRepository extends JpaRepository<Review, Integer> {

    // Find all reviews written about a specific sitter
    List<Review> findBySitterId(Integer sitterId);

    // Find all reviews written by a specific homeowner
    List<Review> findByHomeownerId(Integer homeownerId);

    // Find reviews associated with a specific booking
    List<Review> findByBookingId(Integer bookingId);

    // Find reviews by approval status (e.g., "APPROVED", "PENDING")
    List<Review> findByStatus(String status);
}