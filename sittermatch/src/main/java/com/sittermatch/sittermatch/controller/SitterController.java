package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.SitterReviewHomeownerRequest;
import com.sittermatch.sittermatch.dto.SitterReviewPetRequest;
import com.sittermatch.sittermatch.dto.SitterSendMessageRequest;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterDetailsResponse;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterListResponse;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.model.PetReview;
import com.sittermatch.sittermatch.model.Review;
import com.sittermatch.sittermatch.services.SitterLocationService;
import com.sittermatch.sittermatch.services.SitterService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/sitters")
public class SitterController {

    private final SitterService sitterService;
    private final SitterLocationService sitterLocationService;

    public SitterController(SitterService sitterService, SitterLocationService sitterLocationService) {
        this.sitterService = sitterService;
        this.sitterLocationService = sitterLocationService;
    }

    // GET /api/sitters/{homeownerId}/get-sitters?distanceKm=… (defaults to 40 km when omitted)
    // An empty list is a normal result (no sitters in range), so it returns 200, not 404.
    @GetMapping("/{homeownerId}/get-sitters")
    public ResponseEntity<List<SitterListResponse>> getSitters(
            @PathVariable int homeownerId,
            @RequestParam(required = false) Double distanceKm) {
        return ResponseEntity.ok(sitterLocationService.findNearbySitters(homeownerId, distanceKm));
    }

    @GetMapping("/{sitterId}/get-sitter-details")
    public ResponseEntity<SitterDetailsResponse> getSitterDetails(@PathVariable int sitterId) {
        SitterDetailsResponse sitterDetails = sitterService.getSitterDetails(sitterId);
        if (!sitterDetails.success()) {
            return ResponseEntity.badRequest().body(sitterDetails);
        }
        return ResponseEntity.ok(sitterDetails);
    }

        //Discovery and Listing Interaction
        @GetMapping("/listings/nearby")
        public ResponseEntity<List<Listing>> findNearbyListings(@RequestParam String suburb){
            return ResponseEntity.ok(sitterService.findNearbyListings(suburb));
        }

        @GetMapping("/listings/{listingId}")
        public ResponseEntity<Listing> getListingDetails(@PathVariable Integer listingId){
            return ResponseEntity.ok(sitterService.getListingDetails(listingId));
        }

        //Booking and Calendar Management
        @PutMapping("/bookings/{bookingId}/respond")
        public ResponseEntity<Booking> respontToBooking(
            @PathVariable Integer bookingId,
            @RequestParam String status) {
                return ResponseEntity.ok(sitterService.respondToBooking(bookingId, status));
            }

        @GetMapping("/{sitterId}/bookings")
        public ResponseEntity<List<Booking>> getSitterSchedule(@PathVariable Integer sitterId) {
            return ResponseEntity.ok(sitterService.getSitterSchedule(sitterId));
        }

        @GetMapping("/{sitterId}/bookings/{bookingId}/address")
        public ResponseEntity<String> getConfirmedAddress(
            @PathVariable Integer sitterId,
            @PathVariable Integer bookingId) {
                return ResponseEntity.ok(sitterService.getConfirmedAddress(sitterId, bookingId));
            }

        //Communication and Reviews 
        @PostMapping("/{sitterId}/messages")
        public ResponseEntity<Message> sendMessage(
            @PathVariable Integer sitterId,
            @RequestBody SitterSendMessageRequest request) {
                Message message = sitterService.sendMessage(
                    sitterId,
                    request.homeownerId(),
                    request.sentBy(),
                    request.content()
                );
                return ResponseEntity.ok(message);
            }

        @PostMapping("/{sitterId}/reviews/homeowner")
        public ResponseEntity<Review> reviewHomeowner(
            @PathVariable Integer sitterId,
            @RequestBody SitterReviewHomeownerRequest request) {
                Review review = sitterService.reviewHomeowner(
                    request.bookingId(),
                    sitterId,
                    request.homeownerId(),
                    request.rating(),
                    request.comments()
                );
                return ResponseEntity.ok(review);
            }

        @PostMapping("/{sitterId}/reviews/pet")
        public ResponseEntity<PetReview> reviewPet(
            @PathVariable Integer sitterId,
            @RequestBody SitterReviewPetRequest request) {
                PetReview petReview = sitterService.reviewPet(
                    request.bookingId(),
                    request.petId(),
                    request.rating(),
                    request.notes()
                );
                return ResponseEntity.ok(petReview);
            }
}