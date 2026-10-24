package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.PetReviewResponse;
import com.sittermatch.sittermatch.dto.ReviewRequest;
import com.sittermatch.sittermatch.dto.ReviewResponse;
import com.sittermatch.sittermatch.services.ReviewService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reviews")
@CrossOrigin(origins = "*")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    /** Saves a review. It stays hidden until an admin approves it. */
    @PostMapping("/submit")
    public ResponseEntity<?> submitReview(@RequestBody ReviewRequest request) {
        try {
            return ResponseEntity.ok(reviewService.submitReview(request));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /** Approved reviews homeowners wrote about a sitter. */
    @GetMapping("/sitter/{sitterId}")
    public ResponseEntity<List<ReviewResponse>> getSitterReviews(@PathVariable Integer sitterId) {
        return ResponseEntity.ok(reviewService.getReviewsBySitter(sitterId));
    }

    /** Approved reviews sitters wrote about a homeowner. */
    @GetMapping("/homeowner/{homeownerId}")
    public ResponseEntity<List<ReviewResponse>> getHomeownerReviews(@PathVariable Integer homeownerId) {
        return ResponseEntity.ok(reviewService.getReviewsByHomeowner(homeownerId));
    }

    /** Approved reviews sitters wrote about a homeowner's pets. */
    @GetMapping("/homeowner/{homeownerId}/pets")
    public ResponseEntity<List<PetReviewResponse>> getHomeownerPetReviews(@PathVariable Integer homeownerId) {
        return ResponseEntity.ok(reviewService.getPetReviewsByHomeowner(homeownerId));
    }

    /** All reviews on one booking, including ones still waiting for approval. */
    @GetMapping("/booking/{bookingId}")
    public ResponseEntity<List<ReviewResponse>> getBookingReviews(@PathVariable Integer bookingId) {
        return ResponseEntity.ok(reviewService.getReviewsByBooking(bookingId));
    }
}
