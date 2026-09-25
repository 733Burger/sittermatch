package com.sittermatch.sittermatch.controller;

import java.time.LocalDateTime;
import java.util.Set;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.model.Pet;
import com.sittermatch.sittermatch.model.PetReview;
import com.sittermatch.sittermatch.model.PetType;
import com.sittermatch.sittermatch.model.Review;
import com.sittermatch.sittermatch.model.ServiceType;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repositories.BookingRepository;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.ListingRepository;
import com.sittermatch.sittermatch.repositories.MessageRepository;
import com.sittermatch.sittermatch.repositories.PetRepository;
import com.sittermatch.sittermatch.repositories.PetReviewRepository;
import com.sittermatch.sittermatch.repositories.ReviewRepository;
import com.sittermatch.sittermatch.repositories.SitterRepository;
import com.sittermatch.sittermatch.repositories.UserRepository;

@RestController 
@RequestMapping("/api/test")
public class TestDataSeederController {
    
    private final UserRepository userRepository;
    private SitterRepository sitterRepository;
    private HomeownerRepository homeownerRepository;
    private PetRepository petRepository;
    private ListingRepository listingRepository;
    private BookingRepository bookingRepository;
    private ReviewRepository reviewRepository;
    private PetReviewRepository petReviewRepository;
    private MessageRepository messageRepository;

    

    public TestDataSeederController(UserRepository userRepository, SitterRepository sitterRepository,
            HomeownerRepository homeownerRepository, PetRepository petRepository, ListingRepository listingRepository,
            BookingRepository bookingRepository, ReviewRepository reviewRepository,
            PetReviewRepository petReviewRepository, MessageRepository messageRepository) {
        this.userRepository = userRepository;
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
        this.petRepository = petRepository;
        this.listingRepository = listingRepository;
        this.bookingRepository = bookingRepository;
        this.reviewRepository = reviewRepository;
        this.petReviewRepository = petReviewRepository;
        this.messageRepository = messageRepository;
    }


    @PostMapping("/seed")
    public ResponseEntity<String> seedDatabase() {

        // Wipe old records first to avoid Duplicate Entry errors on re-runs
        messageRepository.deleteAllInBatch();
        petReviewRepository.deleteAllInBatch();
        reviewRepository.deleteAllInBatch();
        bookingRepository.deleteAllInBatch();
        listingRepository.deleteAllInBatch();
        petRepository.deleteAllInBatch();
        sitterRepository.deleteAllInBatch();
        homeownerRepository.deleteAllInBatch();
        userRepository.deleteAllInBatch();

        //1.Creating the sitter user
        User sitterUser = new User(null, "Carl Sitter", "sitteremail@gmail.com", "0829877654", "password123", "SITTER", LocalDateTime.now());
        userRepository.save(sitterUser);

        // Pass null for Sitter ID so JPA populates it via @MapsId from sitterUser
        Sitter sitter = new Sitter(null, sitterUser, true, Set.of(PetType.DOG), "3 years", Set.of(ServiceType.DOG_WALKING), 150.0, 250.0, 4.8, 5);
        sitter = sitterRepository.saveAndFlush(sitter);

        // 2. Create Homeowner User
        User ownerUser = new User(null, "Jessica Homeowner", "owneremail@gmail.com", "0832452432", "password123", "HOMEOWNER", LocalDateTime.now());
        ownerUser = userRepository.saveAndFlush(ownerUser); // Flush to populate ownerUser's ID

        Homeowner homeowner = new Homeowner();
        homeowner.setUser(ownerUser); // Assign parent reference so @MapsId can derive the ID
        homeowner.setIsVerified(true);
        homeowner.setRequirements("Quiet area");
        homeowner.setRating(5.0);
        homeowner.setTotalReviews(2);

        homeowner = homeownerRepository.saveAndFlush(homeowner);

        //3.Create Pet
        Pet pet = new Pet(null, homeowner, "Fetch", "Dog", "Golden Retriever", 3, "Friendly", 5.0, "image.jpg", 1);
        petRepository.save(pet);

        //4.Create Listing
        Listing listing = new Listing(null, homeowner, "Pretoria", "House sitting needed", "2 bed house", "123 Main St", LocalDateTime.now(), LocalDateTime.now().plusDays(3), "OPEN");
        listingRepository.save(listing);

        //5.Create Booking
        Booking booking = new Booking(null, listing, sitter, "DOG_WALKING", LocalDateTime.now(), LocalDateTime.now().plusDays(3), "Walk daily at 1 PM", "CONFIRMED", LocalDateTime.now());
        bookingRepository.save(booking);

        //6.Create Review(Sitter reviewing homeowner or vice versa)
        Review review = new Review(null, booking, sitter, homeowner, 5, "Good experiance", "PUBLISHED");
        reviewRepository.save(review);

        //7.Create Pet Review
        PetReview petReview = new PetReview(null, booking, pet, 5, "Fetch was well behaved");
        petReviewRepository.save(petReview);

        //8.Create Message
        Message message = new Message(null, sitter, homeowner, "HOMEOWNER", "Hi Carl, Looking forward to the dog walk", LocalDateTime.now());
        messageRepository.save(message);

        return ResponseEntity.ok("Database successfully seeded with test data!");
        
    }
}
