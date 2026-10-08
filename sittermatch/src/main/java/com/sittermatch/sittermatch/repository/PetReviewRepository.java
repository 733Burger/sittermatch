package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.PetReview;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PetReviewRepository extends JpaRepository<PetReview, Integer> {

    // Find all reviews written for a specific pet
    List<PetReview> findByPetId(Integer petId);

    // Find all pet reviews associated with a specific booking
    List<PetReview> findByBookingId(Integer bookingId);
}