package com.sittermatch.sittermatch.services;

import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterDetailsResponse;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterListResponse;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterDetailsResponse.ServiceProjection;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.model.Pet;
import com.sittermatch.sittermatch.model.PetReview;
import com.sittermatch.sittermatch.model.Review;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.repository.BookingRepository;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.ListingRepository;
import com.sittermatch.sittermatch.repository.MessageRepository;
import com.sittermatch.sittermatch.repository.PetRepository;
import com.sittermatch.sittermatch.repository.PetReviewRepository;
import com.sittermatch.sittermatch.repository.ReviewRepository;
import com.sittermatch.sittermatch.repository.SavedSitterRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import jakarta.transaction.Transactional;

@Service
public class SitterService {
    private final SitterRepository sitterRepository;
    private final ListingRepository listingRepository;
    private final BookingRepository bookingRepository;
    private final MessageRepository messageRepository;
    private final PetReviewRepository petReviewRepository;
    private final ReviewRepository reviewRepository;
    private final HomeownerRepository homeownerRepository;
    private final PetRepository petRepository;
    private final SavedSitterRepository savedSitterRepository;

    public SitterService(SitterRepository sitterRepository, ListingRepository listingRepository,
            BookingRepository bookingRepository, MessageRepository messageRepository,
            PetReviewRepository petReviewRepository, ReviewRepository reviewRepository,
            HomeownerRepository homeownerRepository, PetRepository petRepository,
            SavedSitterRepository savedSitterRepository) {
        this.sitterRepository = sitterRepository;
        this.listingRepository = listingRepository;
        this.bookingRepository = bookingRepository;
        this.messageRepository = messageRepository;
        this.petReviewRepository = petReviewRepository;
        this.reviewRepository = reviewRepository;
        this.homeownerRepository = homeownerRepository;
        this.petRepository = petRepository;
        this.savedSitterRepository = savedSitterRepository;
    }

    public SitterDetailsResponse getSitterDetails(int sitterId) {
        if (sitterId <= 0) {
            return SitterDetailsResponse.failure("Invalid sitter ID");
        }

        SitterDetailsResponse.SitterDetailsProjection sitterDetails = sitterRepository
                .getSitterDetails(sitterId);
        if (sitterDetails == null) {
            return SitterDetailsResponse.failure("Sitter not found");
        }

        List<String> sitterPetPreferences = sitterRepository.findPetPreferences(sitterId);
        List<ServiceProjection> sitterServices = sitterRepository.findSitterServices(sitterId);

        return SitterDetailsResponse.getResponse(sitterDetails, sitterPetPreferences, sitterServices);
    }

    public List<SitterListResponse> getSitters(int homeownerId) {
        if (homeownerId <= 0) {
            return List.of();
        }

        Set<Integer> savedSitterIds = savedSitterRepository
                .findByHomeownerId(homeownerId)
                .stream()
                .map(savedSitter -> savedSitter.getSitterId())
                .collect(Collectors.toSet());

        return sitterRepository
                .findAll()
                .stream()
                .map(sitter -> toSitterListResponse(sitter, savedSitterIds.contains(sitter.getId())))
                .toList();
    }

    private SitterListResponse toSitterListResponse(Sitter sitter, boolean isSaved) {
        var sitterUserDetails = sitter.getUser();
        return new SitterListResponse(
                sitter.getId(),
                (sitterUserDetails != null) ? sitterUserDetails.getName() : null,
                sitter.getRating(),
                sitter.getTotalReviews(),
                sitter.getDayRate(),
                sitter.getNightRate(),
                sitter.getIsVerified(),
                isSaved,
                sitter.getSuburb());
    }

    public List<Listing> findNearbyListings(String suburb) {
        return listingRepository.findBySuburbAndStatus(suburb, "available");
    }

    public Listing getListingDetails(Integer listingId) {
        Listing listing = listingRepository.findById(listingId)
                .orElseThrow(() -> new RuntimeException("Listing not found"));
        listing.setExactAddress(null);
        return listing;
    }

    @Transactional
    public Booking respondToBooking(Integer bookingId, String status) {
        Booking booking = bookingRepository.findById(bookingId).orElseThrow(() -> new RuntimeException("Booking not found"));
        booking.setStatus(status);

        if ("confirmed".equalsIgnoreCase(status)) {
            booking.getListing().setStatus("closed");
        }

        return bookingRepository.save(booking);
    }

    public List<Booking> getSitterSchedule(Integer sitterId) {
        return bookingRepository.findBySitterId(sitterId);
    }

    public String getConfirmedAddress(Integer sitterId, Integer bookingId) {
        Booking booking = bookingRepository.findById(bookingId).orElseThrow(() -> new RuntimeException("Booking not found"));

        if (!booking.getSitter().getId().equals(sitterId)) {
            throw new SecurityException("Unauthorised access to booking details");
        }

        if (!"confirmed".equalsIgnoreCase(booking.getStatus())) {
            throw new IllegalStateException("Address restricted until booking is confirmed");
        }
        return booking.getListing().getExactAddress();
    }

    @Transactional
    public Message sendMessage(Integer sitterId, Integer homeownerId, String sentBy, String content) {
        Sitter sitter = sitterRepository.findById(sitterId).orElseThrow(() -> new RuntimeException("Sitter not found"));
        Homeowner homeowner = homeownerRepository.findById(homeownerId).orElseThrow(() -> new RuntimeException("Homeowner not found"));

        Message message = new Message();
        message.setSitter(sitter);
        message.setHomeowner(homeowner);
        message.setSentBy(sentBy);
        message.setMessage(content);
        message.setSentAt(LocalDateTime.now());
        return messageRepository.save(message);
    }

    @Transactional
    public Review reviewHomeowner(Integer bookingId, Integer sitterId, Integer homeownerId, Integer rating,
            String comments) {
        Booking booking = bookingRepository.findById(bookingId).orElseThrow(() -> new RuntimeException("Booking not found"));
        Sitter sitter = sitterRepository.findById(sitterId).orElseThrow(() -> new RuntimeException("Sitter not found"));
        Homeowner homeowner = homeownerRepository.findById(homeownerId).orElseThrow(() -> new RuntimeException("Homeowner not found"));

        Review review = new Review();
        review.setBooking(booking);
        review.setSitter(sitter);
        review.setHomeowner(homeowner);
        review.setRating(rating);
        review.setComments(comments);
        review.setReviewedBy("sitter");
        return reviewRepository.save(review);
    }

    @Transactional
    public PetReview reviewPet(Integer bookingId, Integer petId, Integer rating, String notes) {
        Booking booking = bookingRepository.findById(bookingId).orElseThrow(() -> new RuntimeException("Booking not found"));
        Pet pet = petRepository.findById(petId).orElseThrow(() -> new RuntimeException("Pet not found"));

        PetReview petReview = new PetReview();
        petReview.setBooking(booking);
        petReview.setPet(pet);
        petReview.setRating(rating);
        petReview.setNotes(notes);
        return petReviewRepository.save(petReview);
    }
}
