package com.sittermatch.sittermatch.services;

import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashSet;
import java.util.Optional;

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
import com.sittermatch.sittermatch.model.SitterCheck;
import com.sittermatch.sittermatch.repository.BookingRepository;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.ListingRepository;
import com.sittermatch.sittermatch.repository.MessageRepository;
import com.sittermatch.sittermatch.repository.PetRepository;
import com.sittermatch.sittermatch.repository.PetReviewRepository;
import com.sittermatch.sittermatch.repository.ReviewRepository;
import com.sittermatch.sittermatch.repository.SavedSitterRepository;
import com.sittermatch.sittermatch.repository.SitterCheckRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.dto.SitterProfileUpdateRequest;
import com.sittermatch.sittermatch.dto.SitterProfileUpdateResponse;
import com.sittermatch.sittermatch.model.SitterServices;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repository.UserRepository;

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
    private final SitterCheckRepository sitterCheckRepository;
    private final SavedSitterRepository savedSitterRepository;
    private final UserRepository userRepository;

    

    public SitterService(SitterRepository sitterRepository, ListingRepository listingRepository,
                BookingRepository bookingRepository, MessageRepository messageRepository,
                PetReviewRepository petReviewRepository, ReviewRepository reviewRepository,
                HomeownerRepository homeownerRepository, PetRepository petRepository,
                SitterCheckRepository sitterCheckRepository, SavedSitterRepository savedSitterRepository,
                UserRepository userRepository) {
        this.sitterRepository = sitterRepository;
        this.listingRepository = listingRepository;
        this.bookingRepository = bookingRepository;
        this.messageRepository = messageRepository;
        this.petReviewRepository = petReviewRepository;
        this.reviewRepository = reviewRepository;
        this.homeownerRepository = homeownerRepository;
        this.petRepository = petRepository;
        this.sitterCheckRepository = sitterCheckRepository;
        this.savedSitterRepository = savedSitterRepository;
        this.userRepository = userRepository;
}

    public SitterDetailsResponse getSitterDetails(int sitterId) {
        if (sitterId <= 0) {
            return SitterDetailsResponse.failure("Invalid sitter ID");
        }

        SitterDetailsResponse.SitterDetailsProjection sitterDetails = sitterRepository.getSitterDetails(sitterId);
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

    private SitterListResponse toSitterListResponse (Sitter sitter, boolean isSaved) {
        var sitterUserDetails = sitter.getUser();
        return new SitterListResponse(
            sitter.getId(),
            (sitterUserDetails != null) ? sitterUserDetails.getName() : null,
            sitter.getRating(),
            sitter.getTotalReviews(),
            sitter.getDayRate(),
            sitter.getNightRate(),
            sitter.getIsVerified(),
            isSaved
        );
    }

    // Profile and Account Managment
    //Note to Others, experience needs to change to a String value for a description of their experience
    //Possible addition of years_of_experience
//     @Transactional
//     public Sitter updateProfile(Integer sitterId,
//                                 Double dayRate,
//                                 Double nightRate,
//                                 Integer experiance,
//                                 Set<String> preferences,
//                                 Set<String> services) {
//         Sitter sitter = sitterRepository.findById(sitterId).orElseThrow(() -> new RuntimeException("Sitter not found"));
//         sitter.setDayRate(dayRate);
//         sitter.setNightRate(nightRate);
//         sitter.setExperience(experiance);
//         sitter.setPetTypes(preferences);
//         sitter.setServiceTypes(services);
//         return sitterRepository.save(sitter);
//     }

//     @Transactional
//     public SitterCheck submitVerification(Integer sitterId, String type, String idPhotoUrl, String references) {
//             Sitter sitter = sitterRepository.findById(sitterId)
//                             .orElseThrow(() -> new RuntimeException("Sitter not found with id: " + sitterId));

//             SitterCheck check = new SitterCheck();
//             check.setSitterId(sitter.getId());
//             check.setType(type != null ? type : "id");
//             check.setIdPhoto(idPhotoUrl != null ? idPhotoUrl : "");
//             check.setReferences(references != null ? references : "");
//             check.setStatus("pending");

//             try {
//                     return sitterCheckRepository.save(check);
//             } catch (Exception e) {
//                     System.err.println("=== VERIFICATION SAVE ERROR ===");
//                     e.printStackTrace(); // BRINGS THE EXACT DB CAUSE TO THE VERY BOTTOM OF TERMINAL
//                     throw e;
//             }
//     }

        private static final Set<String> ALLOWED_SERVICES = Set.of("STAY_OVER_NIGHT", "WALK_PET", "FEED_PET");
        private static final Set<String> ALLOWED_PETS =
                Set.of("LARGE DOG", "SMALL DOG", "CAT", "BIRD", "REPTILE", "FISH", "EXOTIC");

        @Transactional
        public SitterProfileUpdateResponse updateProfile(int sitterId, SitterProfileUpdateRequest req) {
                Optional<Sitter> found = sitterRepository.findById(sitterId);
                if (found.isEmpty()) {
                return SitterProfileUpdateResponse.failure("Sitter not found");
                }

                String name = req.name() == null ? "" : req.name().trim();
                String email = req.email() == null ? "" : req.email().trim().toLowerCase();
                String phone = req.phone() == null ? "" : req.phone().trim();
                String experience = req.experience() == null ? "" : req.experience().trim();

                if (name.isBlank() || name.length() > 100) {
                return SitterProfileUpdateResponse.failure("Enter a name under 100 characters.");
                }
                if (email.isBlank() || email.length() > 255 || !email.contains("@")) {
                return SitterProfileUpdateResponse.failure("Enter a valid email address.");
                }
                if (phone.length() > 20 || (!phone.isEmpty() && !phone.matches("[0-9+()\\- ]+"))) {
                return SitterProfileUpdateResponse.failure("Enter a phone number under 20 characters.");
                }
                if (experience.length() > 2000) {
                return SitterProfileUpdateResponse.failure("About & experience must be under 2000 characters.");
                }

                if (req.services() == null || req.services().isEmpty()) {
                return SitterProfileUpdateResponse.failure("Select at least one service.");
                }
                Set<SitterServices> newServices = new HashSet<>();
                Double nightRate = null;
                for (var s : req.services()) {
                String type = s.serviceType() == null ? "" : s.serviceType().trim().toUpperCase();
                if (!ALLOWED_SERVICES.contains(type)) {
                        return SitterProfileUpdateResponse.failure("Unknown service type.");
                }
                if (s.price() == null || s.price() <= 0 || s.price() > 1_000_000) {
                        return SitterProfileUpdateResponse.failure("Enter a valid price for every selected service.");
                }
                Integer duration = null;
                if (type.equals("WALK_PET")) {
                        if (s.durationMinutes() == null || s.durationMinutes() <= 0) {
                        return SitterProfileUpdateResponse.failure("Enter the walk length in minutes.");
                        }
                        duration = s.durationMinutes();
                }
                BigDecimal price = BigDecimal.valueOf(s.price()).setScale(2, RoundingMode.HALF_UP);
                if (type.equals("STAY_OVER_NIGHT")) {
                        nightRate = price.doubleValue();
                }
                newServices.add(new SitterServices(type, price, duration));
                }

                Set<String> newPets = new HashSet<>();
                if (req.petPreferences() != null) {
                for (String p : req.petPreferences()) {
                        String v = p == null ? "" : p.trim().toUpperCase();
                        if (!ALLOWED_PETS.contains(v)) {
                        return SitterProfileUpdateResponse.failure("Unknown pet type.");
                        }
                        newPets.add(v);
                }
                }
                if (newPets.isEmpty()) {
                return SitterProfileUpdateResponse.failure("Select at least one pet type.");
                }

                Optional<User> emailOwner = userRepository.findByEmailIgnoreCase(email);
                if (emailOwner.isPresent() && !emailOwner.get().getId().equals(sitterId)) {
                return SitterProfileUpdateResponse.failure("That email is already in use.");
                }

                Sitter sitter = found.get();
                User user = sitter.getUser();
                user.setName(name);
                user.setEmail(email);
                user.setPhone(phone);
                sitter.setExperience(experience);
                sitter.setNightRate(nightRate); // the home screen lists R{nightRate} / nt

                // Clear + flush first so Hibernate deletes the old rows, then insert the new set.
                sitter.getServices().clear();
                sitter.getPetPreferences().clear();
                sitterRepository.saveAndFlush(sitter);
                sitter.getServices().addAll(newServices);
                sitter.getPetPreferences().addAll(newPets);

                userRepository.save(user);
                sitterRepository.save(sitter);

                return new SitterProfileUpdateResponse(true, "Profile updated", name, email, phone);
        }



    // Discovery and Listing Interaction
    public List<Listing> findNearbyListings(String suburb) {
            // Excludes exact address details for public browsing
            return listingRepository.findBySuburbAndStatus(suburb, "available");
    }

    public Listing getListingDetails(Integer listingId) {
            Listing listing = listingRepository.findById(listingId)
                            .orElseThrow(() -> new RuntimeException("Listing not found"));
            listing.setExactAddress(null); // Privacy enforcement
            return listing;
    }

    // Booking and Calendar Management
    @Transactional
    public Booking respondToBooking(Integer bookingId, String status) {
            Booking booking = bookingRepository.findById(bookingId)
                            .orElseThrow(() -> new RuntimeException("Booking not found"));
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
            Booking booking = bookingRepository.findById(bookingId)
                            .orElseThrow(() -> new RuntimeException("Booking not found"));

            if (!booking.getSitter().getId().equals(sitterId)) {
                    throw new SecurityException("Unauthorised access to booking details");
            }
            if (!"confirmed".equalsIgnoreCase(booking.getStatus())) {
                    throw new IllegalStateException("Address restricted until booking is confirmed");
            }
            return booking.getListing().getExactAddress();
    }

    // Communication and Reviews
    @Transactional
    public Message sendMessage(Integer sitterId, Integer homeownerId, String sentBy, String content) {
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
    public Review reviewHomeowner(Integer bookingId, Integer sitterId, Integer homeownerId, Integer rating,
                    String comments) {
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
    public PetReview reviewPet(Integer bookingId, Integer petId, Integer rating, String notes) {
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
