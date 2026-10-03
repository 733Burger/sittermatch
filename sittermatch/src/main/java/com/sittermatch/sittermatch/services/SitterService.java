package com.sittermatch.sittermatch.services;

import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;


import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.model.Pet;
import com.sittermatch.sittermatch.model.PetReview;
import com.sittermatch.sittermatch.model.Review;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.SitterCheck;
import com.sittermatch.sittermatch.repositories.BookingRepository;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.ListingRepository;
import com.sittermatch.sittermatch.repositories.MessageRepository;
import com.sittermatch.sittermatch.repositories.PetRepository;
import com.sittermatch.sittermatch.repositories.PetReviewRepository;
import com.sittermatch.sittermatch.repositories.ReviewRepository;
import com.sittermatch.sittermatch.repositories.SitterCheckRepository;
import com.sittermatch.sittermatch.repositories.SitterRepository;

import jakarta.transaction.Transactional;

@Service
public class SitterService {
   private final SitterRepository sitterRepository;
   private final ListingRepository listingRepository;
   private final  BookingRepository bookingRepository;
   private final MessageRepository messageRepository;
   private final PetReviewRepository petReviewRepository;
   private final ReviewRepository reviewRepository;
   private final HomeownerRepository homeownerRepository;
   private final PetRepository petRepository;
   private final SitterCheckRepository sitterCheckRepository;



   public SitterService(SitterRepository sitterRepository, ListingRepository listingRepository,
                BookingRepository bookingRepository, MessageRepository messageRepository,
                PetReviewRepository petReviewRepository, ReviewRepository reviewRepository,
                HomeownerRepository homeownerRepository, PetRepository petRepository,
                SitterCheckRepository sitterCheckRepository) {
        this.sitterRepository = sitterRepository;
        this.listingRepository = listingRepository;
        this.bookingRepository = bookingRepository;
        this.messageRepository = messageRepository;
        this.petReviewRepository = petReviewRepository;
        this.reviewRepository = reviewRepository;
        this.homeownerRepository = homeownerRepository;
        this.petRepository = petRepository;
        this.sitterCheckRepository = sitterCheckRepository;
}

   //Profile and Account Managment
   @Transactional 
   public Sitter updateProfile(Integer sitterId, Double dayRate, Double nightRate, Integer experiance, Set<String> preferences, Set<String> services) {
    Sitter sitter = sitterRepository.findById(sitterId)
            .orElseThrow(() -> new RuntimeException("Sitter not found"));
    sitter.setDayRate(dayRate);
    sitter.setNightRate(nightRate);
    sitter.setExperience(experiance);
    sitter.setPetTypes(preferences);
    sitter.setServiceTypes(services);
    return sitterRepository.save(sitter);

   }

   @Transactional
public SitterCheck submitVerification(Integer sitterId, String type, String idPhotoUrl, String references) {
    Sitter sitter = sitterRepository.findById(sitterId)
            .orElseThrow(() -> new RuntimeException("Sitter not found with id: " + sitterId));

    SitterCheck check = new SitterCheck();
    check.setSitterId(sitter.getId());
    check.setType(type != null ? type : "id");
    check.setIdPhoto(idPhotoUrl != null ? idPhotoUrl : "");
    check.setReferences(references != null ? references : "");
    check.setStatus("pending");

    try {
        return sitterCheckRepository.save(check);
    } catch (Exception e) {
        System.err.println("=== VERIFICATION SAVE ERROR ===");
        e.printStackTrace(); // BRINGS THE EXACT DB CAUSE TO THE VERY BOTTOM OF TERMINAL
        throw e;
    }
}

   //Discovery and Listing Interaction
   public List<Listing> findNearbyListings(String suburb){
    //Excludes exact address details for public browsing
    return listingRepository.findBySuburbAndStatus(suburb, "available");
   }

   public Listing getListingDetails(Integer listingId){
    Listing listing = listingRepository.findById(listingId)
            .orElseThrow(() -> new RuntimeException("Listing not found"));
    listing.setExactAddress(null); //Privacy enforcement
    return listing;
   }
   
   //Booking and Calendar Management
   @Transactional public Booking respondToBooking(Integer bookingId, String status){
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        booking.setStatus(status);
        if("confirmed".equalsIgnoreCase(status)){
                booking.getListing().setStatus("closed");
        }
        return bookingRepository.save(booking);
   }

   public List<Booking> getSitterSchedule(Integer sitterId){
        return bookingRepository.findBySitterId(sitterId);
   }

   public String getConfirmedAddress(Integer sitterId, Integer bookingId){
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));

        if(!booking.getSitter().getId().equals(sitterId)){
                throw new SecurityException("Unauthorised access to booking details");
        }
        if(!"confirmed".equalsIgnoreCase(booking.getStatus())){
                throw new IllegalStateException("Address restricted until booking is confirmed");
        }
        return booking.getListing().getExactAddress();
   }

   //Communication and Reviews
   @Transactional 
   public Message sendMessage(Integer sitterId, Integer homeownerId, String sentBy, String content){
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));
        Homeowner homeowner = homeownerRepository.findById(homeownerId)
                .orElseThrow(() -> new RuntimeException("Homeowner not found"));

        Message message = new Message();
        message.setSitter(sitter);
        message.setHomeowner(homeowner);
        message.setSentBy(sentBy);
        message.setMessage(content);
        message.setSentAt(LocalDateTime.now());
        return messageRepository.save(message);
   }

   @Transactional
   public Review reviewHomeowner(Integer bookingId, Integer sitterId, Integer homeownerId, Integer rating, String comments){
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new RuntimeException("Sitter not found"));
        Homeowner homeowner = homeownerRepository.findById(homeownerId)
                .orElseThrow(() -> new RuntimeException("Homeowner not found"));   
                     
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
   public PetReview reviewPet(Integer bookingId, Integer petId, Integer rating, String notes){
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new RuntimeException("Pet not found"));


        PetReview petReview = new PetReview();
        petReview.setBooking(booking);
        petReview.setPet(pet);
        petReview.setRating(rating);
        petReview.setNotes(notes);
        return petReviewRepository.save(petReview);
   }
}
