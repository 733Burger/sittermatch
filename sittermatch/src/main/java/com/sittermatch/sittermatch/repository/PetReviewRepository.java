package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.PetReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PetReviewRepository extends JpaRepository<PetReview, Integer> {
    List<PetReview> findByBookingId(Integer bookingId);
    List<PetReview> findByPetId(Integer petId);
    List<PetReview> findByPetHomeownerIdOrderByIdDesc(Integer homeownerId);
}