package com.sittermatch.sittermatch.services;

import com.sittermatch.sittermatch.dto.PetReviewDto;
import com.sittermatch.sittermatch.dto.PetReviewResponse;
import com.sittermatch.sittermatch.dto.ReviewRequest;
import com.sittermatch.sittermatch.dto.ReviewResponse;
import com.sittermatch.sittermatch.dto.admin.AdminReviewDto;
import com.sittermatch.sittermatch.model.*;
import com.sittermatch.sittermatch.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Stay reviews. A new review is PENDING and hidden until an admin approves it (PUBLISHED) or
 * removes it (REMOVED). Ratings on sitter, homeowner and pet profiles only count published reviews.
 */
@Service
public class ReviewService {

    public static final String PENDING = "PENDING";
    public static final String PUBLISHED = "PUBLISHED";
    public static final String REMOVED = "REMOVED";

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("d MMM yyyy");

    private final ReviewRepository reviewRepository;
    private final PetReviewRepository petReviewRepository;
    private final BookingRepository bookingRepository;
    private final SitterRepository sitterRepository;
    private final HomeownerRepository homeownerRepository;
    private final PetRepository petRepository;

    public ReviewService(ReviewRepository reviewRepository,
                         PetReviewRepository petReviewRepository,
                         BookingRepository bookingRepository,
                         SitterRepository sitterRepository,
                         HomeownerRepository homeownerRepository,
                         PetRepository petRepository) {
        this.reviewRepository = reviewRepository;
        this.petReviewRepository = petReviewRepository;
        this.bookingRepository = bookingRepository;
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
        this.petRepository = petRepository;
    }

    /** Saves a review for a booking and marks the booking completed. It waits for an admin to approve it. */
    @Transactional
    public ReviewResponse submitReview(ReviewRequest request) {
        if (request.bookingId() == null) {
            throw new IllegalArgumentException("Booking ID is required.");
        }

        Booking booking = bookingRepository.findById(request.bookingId())
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + request.bookingId()));

        String reviewedBy = request.reviewedBy() != null ? request.reviewedBy().toUpperCase() : "HOMEOWNER";
        if (!reviewedBy.equals("SITTER") && !reviewedBy.equals("HOMEOWNER")) {
            throw new IllegalArgumentException("reviewedBy must be SITTER or HOMEOWNER.");
        }
        if (reviewRepository.existsByBookingIdAndReviewedByIgnoreCase(booking.getId(), reviewedBy)) {
            throw new IllegalStateException("You have already reviewed this stay.");
        }
        int rating = request.rating() != null ? request.rating() : 5;
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5.");
        }

        Sitter sitter = booking.getSitter();
        if (sitter == null && request.sitterId() != null) {
            sitter = sitterRepository.findById(request.sitterId()).orElse(null);
        }
        if (sitter == null) {
            throw new IllegalStateException("This booking has no sitter to review.");
        }

        Homeowner homeowner = (booking.getListing() != null) ? booking.getListing().getHomeowner() : null;
        if (homeowner == null && request.homeownerId() != null) {
            homeowner = homeownerRepository.findById(request.homeownerId()).orElse(null);
        }

        Review review = new Review();
        review.setBooking(booking);
        review.setSitter(sitter);
        review.setHomeowner(homeowner);
        review.setReviewedBy(reviewedBy);
        review.setRating(rating);
        review.setComments(request.comments());
        review.setStatus(PENDING);
        review.setCreatedAt(LocalDateTime.now());
        Review savedReview = reviewRepository.save(review);

        // Only the sitter rates the pets they looked after.
        if (reviewedBy.equals("SITTER") && request.petReviews() != null) {
            for (PetReviewDto pDto : request.petReviews()) {
                if (pDto.petId() == null) continue;
                petRepository.findById(pDto.petId()).ifPresent(pet -> {
                    PetReview petReview = new PetReview();
                    petReview.setBooking(booking);
                    petReview.setPet(pet);
                    petReview.setRating(pDto.rating() != null ? pDto.rating() : 5);
                    petReview.setNotes(pDto.notes());
                    petReviewRepository.save(petReview);
                });
            }
        }

        if (!"COMPLETED".equalsIgnoreCase(booking.getStatus())) {
            booking.setStatus("COMPLETED");
            bookingRepository.save(booking);
        }

        return mapToDTO(savedReview);
    }

    /** Published reviews homeowners wrote about this sitter. */
    public List<ReviewResponse> getReviewsBySitter(Integer sitterId) {
        return reviewRepository.findBySitterIdAndReviewedByIgnoreCaseAndStatus(sitterId, "HOMEOWNER", PUBLISHED).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /** Published reviews sitters wrote about this homeowner. */
    public List<ReviewResponse> getReviewsByHomeowner(Integer homeownerId) {
        return reviewRepository.findByHomeownerIdAndReviewedByIgnoreCaseAndStatus(homeownerId, "SITTER", PUBLISHED).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /** Reviews of this homeowner's pets, once the sitter's review for that stay is published. */
    public List<PetReviewResponse> getPetReviewsByHomeowner(Integer homeownerId) {
        return petReviewRepository.findByPetHomeownerIdOrderByIdDesc(homeownerId).stream()
                .map(pr -> {
                    Review sitterReview = pr.getBooking() == null ? null
                            : reviewRepository.findByBookingId(pr.getBooking().getId()).stream()
                                    .filter(r -> isBySitter(r) && PUBLISHED.equalsIgnoreCase(r.getStatus()))
                                    .findFirst().orElse(null);
                    if (sitterReview == null) return null;
                    return new PetReviewResponse(
                            pr.getId(),
                            pr.getPet().getId(),
                            pr.getPet().getName(),
                            pr.getRating(),
                            pr.getNotes() == null ? "" : pr.getNotes(),
                            sitterName(sitterReview),
                            sitterReview.getCreatedAt() == null ? null : sitterReview.getCreatedAt().format(DATE));
                })
                .filter(r -> r != null)
                .collect(Collectors.toList());
    }

    /** The reviews on a booking, pending ones included, so each side can see what they wrote. */
    public List<ReviewResponse> getReviewsByBooking(Integer bookingId) {
        return reviewRepository.findByBookingId(bookingId).stream()
                .filter(r -> !REMOVED.equalsIgnoreCase(r.getStatus()))
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    // ---------- Admin ----------

    public List<AdminReviewDto> getPendingReviews() {
        return reviewRepository.findByStatusOrderByIdAsc(PENDING).stream()
                .map(r -> new AdminReviewDto(
                        r.getId(),
                        reviewerName(r),
                        r.getReviewedBy() == null ? "" : r.getReviewedBy().toUpperCase(),
                        revieweeName(r),
                        r.getRating() == null ? 0.0 : r.getRating().doubleValue(),
                        r.getComments() == null ? "" : r.getComments(),
                        r.getCreatedAt() == null ? "" : r.getCreatedAt().format(DATE),
                        null))
                .collect(Collectors.toList());
    }

    /** Approving publishes the review; otherwise it is removed. Ratings are worked out again either way. */
    @Transactional
    public void resolveReview(Integer reviewId, boolean approved) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("Review not found with ID: " + reviewId));
        review.setStatus(approved ? PUBLISHED : REMOVED);
        reviewRepository.save(review);

        if (isBySitter(review)) {
            if (review.getHomeowner() != null) refreshHomeownerRating(review.getHomeowner());
            if (review.getBooking() != null) {
                petReviewRepository.findByBookingId(review.getBooking().getId())
                        .forEach(pr -> refreshPetRating(pr.getPet()));
            }
        } else if (review.getSitter() != null) {
            refreshSitterRating(review.getSitter());
        }
    }

    private void refreshSitterRating(Sitter sitter) {
        List<Review> published = reviewRepository
                .findBySitterIdAndReviewedByIgnoreCaseAndStatus(sitter.getId(), "HOMEOWNER", PUBLISHED);
        sitter.setRating(average(published.stream().map(Review::getRating).toList()));
        sitter.setTotalReviews(published.size());
        sitterRepository.save(sitter);
    }

    private void refreshHomeownerRating(Homeowner homeowner) {
        List<Review> published = reviewRepository
                .findByHomeownerIdAndReviewedByIgnoreCaseAndStatus(homeowner.getId(), "SITTER", PUBLISHED);
        homeowner.setRating(average(published.stream().map(Review::getRating).toList()));
        homeowner.setTotalReviews(published.size());
        homeownerRepository.save(homeowner);
    }

    /** A pet rating counts once the sitter's review for that booking is published. */
    private void refreshPetRating(Pet pet) {
        if (pet == null) return;
        List<Integer> ratings = petReviewRepository.findByPetId(pet.getId()).stream()
                .filter(pr -> pr.getBooking() != null && reviewRepository.findByBookingId(pr.getBooking().getId()).stream()
                        .anyMatch(r -> isBySitter(r) && PUBLISHED.equalsIgnoreCase(r.getStatus())))
                .map(PetReview::getRating)
                .toList();
        pet.setBehaviourScore(ratings.isEmpty() ? null : average(ratings));
        pet.setTotalReviews(ratings.size());
        petRepository.save(pet);
    }

    private double average(List<Integer> ratings) {
        return ratings.stream().filter(r -> r != null).mapToInt(Integer::intValue).average().orElse(0.0);
    }

    private boolean isBySitter(Review r) {
        return "SITTER".equalsIgnoreCase(r.getReviewedBy());
    }

    private String sitterName(Review r) {
        return r.getSitter() != null && r.getSitter().getUser() != null ? r.getSitter().getUser().getName() : "Sitter";
    }

    private String homeownerName(Review r) {
        return r.getHomeowner() != null && r.getHomeowner().getUser() != null ? r.getHomeowner().getUser().getName() : "Homeowner";
    }

    private String reviewerName(Review r) {
        return isBySitter(r) ? sitterName(r) : homeownerName(r);
    }

    private String revieweeName(Review r) {
        return isBySitter(r) ? homeownerName(r) : sitterName(r);
    }

    private ReviewResponse mapToDTO(Review review) {
        return new ReviewResponse(
                review.getId(),
                review.getBooking() != null ? review.getBooking().getId() : null,
                review.getSitter() != null ? review.getSitter().getId() : null,
                review.getHomeowner() != null ? review.getHomeowner().getId() : null,
                review.getReviewedBy() == null ? null : review.getReviewedBy().toUpperCase(),
                review.getRating(),
                review.getComments(),
                review.getStatus(),
                reviewerName(review),
                revieweeName(review),
                review.getCreatedAt()
        );
    }
}
