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

    // 1. Create Sitter User and flush to generate ID
    User sitterUser = new User(null, "Carl Sitter", "sitteremail@gmail.com", "0829877654", "password123", "SITTER", LocalDateTime.now());
    sitterUser = userRepository.saveAndFlush(sitterUser);

    // 2. Create Sitter matching Sitter.java's actual fields & constructor
    Sitter sitter = new Sitter(
        null,        // id (mapped from User via @MapsId)
        sitterUser,  // user
        3,           // experience (Integer)
        150.0,       // dayRate (Double)
        250.0,       // nightRate (Double)
        4.8,         // rating (Double)
        5,           // totalReviews (Integer)
        true         // isVerified (Boolean)
    );

    // Set collections (Set<String>)
    sitter.setPetTypes(Set.of("DOG")); // or Set.of(PetType.DOG.name()) if using an Enum
    sitter.setServiceTypes(Set.of("DOG_WALKING")); // or Set.of(ServiceType.DOG_WALKING.name())

    sitter = sitterRepository.saveAndFlush(sitter);

    // 3. Create Homeowner User
    User ownerUser = new User(null, "Jessica Homeowner", "owneremail@gmail.com", "0832452432", "password123", "HOMEOWNER", LocalDateTime.now());
    ownerUser = userRepository.saveAndFlush(ownerUser);

    Homeowner homeowner = new Homeowner();
    homeowner.setUser(ownerUser);
    homeowner.setIsVerified(true);
    homeowner.setRequirements("Quiet area");
    homeowner.setRating(5.0);
    homeowner.setTotalReviews(2);

    homeowner = homeownerRepository.saveAndFlush(homeowner);

    // 4. Create Pet
    Pet pet = new Pet(null, homeowner, "Fetch", "Dog", "Golden Retriever", 3, "Friendly", 5.0, "image.jpg", 1);
    petRepository.save(pet);

    // 5. Create Listing
    Listing listing = new Listing(null, homeowner, "Pretoria", "House sitting needed", "2 bed house", "123 Main St", LocalDateTime.now(), LocalDateTime.now().plusDays(3), "OPEN");
    listingRepository.save(listing);

    // 6. Create Booking
    Booking booking = new Booking(null, listing, sitter, "DOG_WALKING", LocalDateTime.now(), LocalDateTime.now().plusDays(3), "Walk daily at 1 PM", "CONFIRMED", LocalDateTime.now());
    bookingRepository.save(booking);

    // 7. Create Review
    Review review = new Review(null, booking, sitter, homeowner, 5, "Good experience", "PUBLISHED");
    reviewRepository.save(review);

    // 8. Create Pet Review
    PetReview petReview = new PetReview(null, booking, pet, 5, "Fetch was well behaved");
    petReviewRepository.save(petReview);

    // 9. Create Message
    Message message = new Message(null, sitter, homeowner, "HOMEOWNER", "Hi Carl, Looking forward to the dog walk", LocalDateTime.now());
    messageRepository.save(message);

    return ResponseEntity.ok("Database successfully seeded with test data!");
}
}
