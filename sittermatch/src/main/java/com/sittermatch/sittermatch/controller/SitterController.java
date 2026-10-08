package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.SitterListResponse;
import com.sittermatch.sittermatch.dto.SitterReviewHomeownerRequest;
import com.sittermatch.sittermatch.dto.SitterReviewPetRequest;
import com.sittermatch.sittermatch.dto.SitterSendMessageRequest;
import com.sittermatch.sittermatch.dto.SubmitSitterVerificationRequest;
import com.sittermatch.sittermatch.dto.UpdateSitterProfileRequest;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.model.PetReview;
import com.sittermatch.sittermatch.model.Review;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.SitterCheck;
import com.sittermatch.sittermatch.services.SitterService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;


@RestController
@RequestMapping("/api/sitters")
public class SitterController {

    private final SitterService sitterService;

    public SitterController(SitterService sitterService) {
        this.sitterService = sitterService;
    }

    @GetMapping("get-sitters")
    public ResponseEntity<List<SitterListResponse>> getSitters() {
        List<SitterListResponse> sitters = sitterService.getSitters();
        if (sitters == null || sitters.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(sitters);
    }
    

    //Profile and Account Managment
    @PutMapping("/{sitterId}/profile")
    public ResponseEntity<Sitter> updateProfile(
                @PathVariable Integer sitterId,
        @RequestBody UpdateSitterProfileRequest request){
            Sitter updatedSitter = sitterService.updateProfile(
                sitterId,
                request.dayRate(),
                request.nightRate(),
                request.experience(),
                request.prefrences(),
                request.services()
            );
            return ResponseEntity.ok(updatedSitter);
        }

        @PostMapping("/{sitterId}/verification")
        public ResponseEntity<SitterCheck> submitVerification(
            @PathVariable Integer sitterId,
            @RequestBody SubmitSitterVerificationRequest request) {
                SitterCheck check = sitterService.submitVerification(
                    sitterId,
                    request.type(),
                    request.idPhotoUrl(),
                    request.references()
                );
                return ResponseEntity.ok(check);
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