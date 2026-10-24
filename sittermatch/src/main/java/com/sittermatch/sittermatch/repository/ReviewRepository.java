package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Integer> {
    List<Review> findByBookingId(Integer bookingId);
    List<Review> findBySitterId(Integer sitterId);
    List<Review> findByHomeownerId(Integer homeownerId);
    boolean existsByBookingIdAndReviewedBy(Integer bookingId, String reviewedBy);
    // reviewed_by has been saved as both "sitter" and "SITTER".
    boolean existsByBookingIdAndReviewedByIgnoreCase(Integer bookingId, String reviewedBy);
    List<Review> findBySitterIdAndReviewedByIgnoreCaseAndStatus(Integer sitterId, String reviewedBy, String status);
    List<Review> findByHomeownerIdAndReviewedByIgnoreCaseAndStatus(Integer homeownerId, String reviewedBy, String status);
    List<Review> findByStatusOrderByIdAsc(String status);
}
