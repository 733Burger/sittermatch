package com.sittermatch.sittermatch.services;

import com.sittermatch.sittermatch.dto.BookingCreateRequest;
import com.sittermatch.sittermatch.dto.BookingOfferResponse;
import com.sittermatch.sittermatch.dto.BookingResponse;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.BookingOffer;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.repository.BookingOfferRepository;
import com.sittermatch.sittermatch.repository.BookingRepository;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.ListingRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.dto.BookingPricesRequest;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterDetailsResponse.ServiceProjection;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.repository.MessageRepository;
import com.sittermatch.sittermatch.model.BookingDismissal;
import com.sittermatch.sittermatch.repository.BookingDismissalRepository;
import com.sittermatch.sittermatch.repository.PetReviewRepository;
import com.sittermatch.sittermatch.repository.ReviewRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class BookingService {

    private final BookingRepository bookingRepository;
    private final ListingRepository listingRepository;
    private final SitterRepository sitterRepository;
    private final HomeownerRepository homeownerRepository;
    private final MessageRepository messageRepository;
    private final ReviewRepository reviewRepository;
    private final PetReviewRepository petReviewRepository;
    private final BookingDismissalRepository dismissalRepository;
    private final BookingOfferRepository offerRepository;

    public BookingService(BookingRepository bookingRepository,
                          ListingRepository listingRepository,
                          SitterRepository sitterRepository,
                          HomeownerRepository homeownerRepository,
                          MessageRepository messageRepository,
                          ReviewRepository reviewRepository,
                          PetReviewRepository petReviewRepository,
                          BookingDismissalRepository dismissalRepository,
                          BookingOfferRepository offerRepository) {
        this.dismissalRepository = dismissalRepository;
        this.messageRepository = messageRepository;
        this.reviewRepository = reviewRepository;
        this.petReviewRepository = petReviewRepository;
        this.bookingRepository = bookingRepository;
        this.listingRepository = listingRepository;
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
        this.offerRepository = offerRepository;
    }

    public List<BookingResponse> getAllBookings() {
        return bookingRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * A sitter's jobs, without the ones they declined or that were cancelled, plus open bookings
     * (no sitter yet) that they haven't declined. A sitter only sees their own offer, not other sitters'.
     */
    public List<BookingResponse> getBookingsForSitter(Integer sitterId) {
        var own = bookingRepository.findBySitterId(sitterId).stream()
                .filter(b -> !hasStatus(b, "DECLINED") && !hasStatus(b, "CANCELLED"));
        // TODO: only offer open bookings to sitters near the homeowner once matching by location is built.
        var open = bookingRepository.findBySitterIsNullAndStatus("PENDING").stream()
                .filter(b -> !dismissalRepository.existsByBookingIdAndSitterId(b.getId(), sitterId));
        return java.util.stream.Stream.concat(own, open)
                .map(b -> mapToDTO(b, sitterId))
                .collect(Collectors.toList());
    }

    /** A sitter declines an open booking: it is hidden from them but stays open for other sitters. */
    @Transactional
    public void dismissOpenBooking(Integer bookingId, Integer sitterId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));
        if (booking.getSitter() != null) {
            throw new IllegalStateException("This booking already has a sitter.");
        }
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new IllegalArgumentException("Sitter not found"));
        offerRepository.findByBookingIdAndSitterId(bookingId, sitterId).ifPresent(offerRepository::delete);
        if (!dismissalRepository.existsByBookingIdAndSitterId(bookingId, sitterId)) {
            dismissalRepository.save(new BookingDismissal(booking, sitter));
        }
    }

    /** A homeowner's bookings. Declined ones stay so the homeowner can see the sitter said no. */
    public List<BookingResponse> getBookingsForHomeowner(Integer homeownerId) {
        return bookingRepository.findByListingHomeownerId(homeownerId).stream()
                .filter(b -> !hasStatus(b, "CANCELLED"))
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    private boolean hasStatus(Booking booking, String status) {
        return booking.getStatus() != null && booking.getStatus().equalsIgnoreCase(status);
    }

    /** Permanently deletes a booking, with any reviews written for it. Returns false if it does not exist. */
    @Transactional
    public boolean deleteBooking(Integer bookingId) {
        if (!bookingRepository.existsById(bookingId)) return false;
        petReviewRepository.deleteAll(petReviewRepository.findByBookingId(bookingId));
        reviewRepository.deleteAll(reviewRepository.findByBookingId(bookingId));
        offerRepository.deleteAll(offerRepository.findByBookingIdOrderByCreatedAtAsc(bookingId));
        bookingRepository.deleteById(bookingId);
        return true;
    }

    public Optional<BookingResponse> getBookingById(Integer id) {
        return bookingRepository.findById(id).map(this::mapToDTO);
    }

 public BookingResponse createBooking(BookingCreateRequest request) {
        Listing listing = resolveListing(request);

        // With no sitter chosen, the booking stays open until the homeowner accepts a sitter's offer.
        Sitter sitter = request.sitterId() == null ? null
                : sitterRepository.findById(request.sitterId())
                        .orElseThrow(() -> new IllegalArgumentException("Sitter not found"));

        Booking booking = new Booking();
        booking.setListing(listing);
        booking.setSitter(sitter);
        booking.setBookingType(request.bookingType() != null ? request.bookingType() : "Standard");
        booking.setStartDate(request.startDate());
        booking.setEndDate(request.endDate());
        booking.setNotes(request.notes());
        booking.setStatus("PENDING");

        Booking saved = bookingRepository.save(booking);
        return mapToDTO(saved);
    }

    @Transactional
    public BookingResponse updateBookingStatus(Integer bookingId, String newStatus) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));

        if ("CONFIRMED".equalsIgnoreCase(newStatus) || "ACCEPTED".equalsIgnoreCase(newStatus)) {
            if (booking.getSitter() == null) {
                throw new IllegalStateException("Accept one of the sitters' offers instead.");
            }
            // A sitter the booking was sent to who made an offer: accept it at the offered prices.
            if (offerRepository.findByBookingIdAndSitterId(bookingId, booking.getSitter().getId()).isPresent()) {
                return acceptOffer(bookingId, booking.getSitter().getId());
            }
        }

        booking.setStatus(newStatus.toUpperCase());
        if ("CONFIRMED".equalsIgnoreCase(newStatus) || "ACCEPTED".equalsIgnoreCase(newStatus)) {
            booking.setConfirmedAt(LocalDateTime.now());
            // The booking is taken, so other sitters' offers no longer apply.
            offerRepository.deleteAll(offerRepository.findByBookingIdOrderByCreatedAtAsc(bookingId));
        }

        Booking updated = bookingRepository.save(booking);
        return mapToDTO(updated);
    }

    /**
     * What the chat between a sitter and a homeowner shows: the sitter's open offer on one of the
     * homeowner's bookings if there is one, otherwise their most recent booking that is still open.
     */
    public Optional<BookingResponse> getActiveBookingBetween(Integer sitterId, Integer homeownerId) {
        Optional<BookingResponse> offer = offerRepository.findBySitterId(sitterId).stream()
                .filter(o -> o.getBooking().getListing() != null
                        && o.getBooking().getListing().getHomeowner() != null
                        && homeownerId.equals(o.getBooking().getListing().getHomeowner().getId())
                        && hasStatus(o.getBooking(), "PENDING"))
                .findFirst()
                .map(this::mapOfferToDTO);
        if (offer.isPresent()) return offer;

        return bookingRepository
                .findByListingHomeownerIdAndSitterIdOrderByStartDateDesc(homeownerId, sitterId).stream()
                .filter(x -> x.getStatus() != null
                        && java.util.Set.of("PENDING", "REQUESTED", "ACCEPTED", "CONFIRMED", "ONGOING")
                                .contains(x.getStatus().toUpperCase()))
                .findFirst()
                .map(this::mapToDTO);
    }

    /**
     * Sitter offers to take a pending booking. The offer uses the sitter's own prices for the
     * services the booking asks for, plus any prices the sitter set for services they don't normally
     * offer. The booking stays PENDING so other sitters can offer too; the homeowner gets a chat message.
     */
    @Transactional
    public BookingResponse requestAccept(Integer bookingId, Integer sitterId, BookingPricesRequest extraPrices) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));
        if (!"PENDING".equalsIgnoreCase(booking.getStatus())) {
            throw new IllegalStateException("Only pending bookings can get offers. Current status: " + booking.getStatus());
        }
        if (sitterId == null) {
            if (booking.getSitter() == null) throw new IllegalArgumentException("Sign in as a sitter to offer on this booking.");
            sitterId = booking.getSitter().getId();
        }
        if (booking.getSitter() != null && !booking.getSitter().getId().equals(sitterId)) {
            throw new IllegalStateException("This booking was sent to another sitter.");
        }
        Sitter sitter = sitterRepository.findById(sitterId)
                .orElseThrow(() -> new IllegalArgumentException("Sitter not found"));

        String type = booking.getBookingType() == null ? "" : booking.getBookingType().toUpperCase();
        boolean needsNight = type.contains("NIGHT");
        boolean needsVisit = type.contains("DROP") || type.contains("VISIT") || type.contains("FEED");
        boolean needsWalk = type.contains("WALK");

        BookingOffer offer = offerRepository.findByBookingIdAndSitterId(bookingId, sitterId)
                .orElseGet(() -> new BookingOffer(booking, sitter));
        offer.setPricePerNight(null);
        offer.setPricePerVisit(null);
        offer.setPricePerWalk(null);
        for (ServiceProjection svc : sitterRepository.findSitterServices(sitterId)) {
            String t = svc.getServiceType() == null ? "" : svc.getServiceType().toUpperCase();
            if (t.contains("NIGHT") && needsNight) offer.setPricePerNight(svc.getPrice());
            else if ((t.contains("DROP") || t.contains("VISIT") || t.contains("FEED")) && needsVisit) offer.setPricePerVisit(svc.getPrice());
            else if (t.contains("WALK") && needsWalk) offer.setPricePerWalk(svc.getPrice());
        }

        // Prices the sitter set in the app for services missing from their profile.
        if (extraPrices != null) {
            if (needsNight && extraPrices.pricePerNight() != null) offer.setPricePerNight(checkPrice(extraPrices.pricePerNight()));
            if (needsVisit && extraPrices.pricePerVisit() != null) offer.setPricePerVisit(checkPrice(extraPrices.pricePerVisit()));
            if (needsWalk && extraPrices.pricePerWalk() != null) offer.setPricePerWalk(checkPrice(extraPrices.pricePerWalk()));
        }

        List<String> missing = new java.util.ArrayList<>();
        if (needsNight && offer.getPricePerNight() == null) missing.add("overnight stay");
        if (needsVisit && offer.getPricePerVisit() == null) missing.add("drop-in feeding visit");
        if (needsWalk && offer.getPricePerWalk() == null) missing.add("dog walk");
        if (!missing.isEmpty()) {
            throw new IllegalStateException("Set a price for: " + String.join(", ", missing) + ".");
        }

        BookingOffer saved = offerRepository.save(offer);

        Message m = new Message();
        m.setSitter(sitter);
        m.setHomeowner(booking.getListing().getHomeowner());
        m.setSentBy("SITTER");
        m.setMessage("I've sent an offer for your " + serviceSummary(booking.getBookingType()).toLowerCase()
                + dateRange(booking) + ". You can accept it here, or compare all offers under Bookings.");
        m.setSentAt(LocalDateTime.now());
        m.setIsRead(false);
        messageRepository.save(m);

        return mapOfferToDTO(saved);
    }

    /**
     * Homeowner accepts one sitter's offer. That sitter gets the booking at the offered prices and
     * every other offer on the booking is deleted.
     */
    @Transactional
    public BookingResponse acceptOffer(Integer bookingId, Integer sitterId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));
        Optional<BookingOffer> found = offerRepository.findByBookingIdAndSitterId(bookingId, sitterId);

        if (found.isPresent()) {
            if (!hasStatus(booking, "PENDING")) {
                throw new IllegalStateException("This booking is no longer taking offers.");
            }
            BookingOffer offer = found.get();
            booking.setSitter(offer.getSitter());
            booking.setPricePerNight(offer.getPricePerNight());
            booking.setPricePerVisit(offer.getPricePerVisit());
            booking.setPricePerWalk(offer.getPricePerWalk());
        } else if (!(hasStatus(booking, "REQUESTED") && booking.getSitter() != null
                && booking.getSitter().getId().equals(sitterId))) {
            // REQUESTED is how sitter requests were stored before offers existed.
            throw new IllegalStateException("This sitter has no offer on the booking.");
        }

        booking.setStatus("ACCEPTED");
        booking.setConfirmedAt(LocalDateTime.now());
        Booking saved = bookingRepository.save(booking);
        offerRepository.deleteAll(offerRepository.findByBookingIdOrderByCreatedAtAsc(bookingId));
        return mapToDTO(saved);
    }

    /** Homeowner turns down an offer, or the sitter withdraws it. The booking stays open to others. */
    @Transactional
    public void declineOffer(Integer bookingId, Integer sitterId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));
        Optional<BookingOffer> offer = offerRepository.findByBookingIdAndSitterId(bookingId, sitterId);
        if (offer.isPresent()) {
            offerRepository.delete(offer.get());
        } else if (hasStatus(booking, "REQUESTED")) {
            booking.setStatus("PENDING");
            bookingRepository.save(booking);
        } else {
            throw new IllegalStateException("This sitter has no offer on the booking.");
        }
    }

    /** Homeowner edits the prices in a sitter's offer before accepting it. */
    @Transactional
    public BookingResponse updatePrices(Integer bookingId, Integer sitterId, BookingPricesRequest req) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));

        Optional<BookingOffer> found = sitterId == null ? Optional.empty()
                : offerRepository.findByBookingIdAndSitterId(bookingId, sitterId);
        if (found.isPresent()) {
            BookingOffer offer = found.get();
            if (req.pricePerNight() != null) offer.setPricePerNight(checkPrice(req.pricePerNight()));
            if (req.pricePerVisit() != null) offer.setPricePerVisit(checkPrice(req.pricePerVisit()));
            if (req.pricePerWalk() != null) offer.setPricePerWalk(checkPrice(req.pricePerWalk()));
            return mapOfferToDTO(offerRepository.save(offer));
        }

        if (!"REQUESTED".equalsIgnoreCase(booking.getStatus())) {
            throw new IllegalStateException("Prices can only be changed while the sitter's offer is open.");
        }
        if (req.pricePerNight() != null) booking.setPricePerNight(checkPrice(req.pricePerNight()));
        if (req.pricePerVisit() != null) booking.setPricePerVisit(checkPrice(req.pricePerVisit()));
        if (req.pricePerWalk() != null) booking.setPricePerWalk(checkPrice(req.pricePerWalk()));
        return mapToDTO(bookingRepository.save(booking));
    }

    private BigDecimal checkPrice(BigDecimal p) {
        if (p.signum() <= 0) throw new IllegalArgumentException("Price must be above 0.");
        return p;
    }

    private Listing resolveListing(BookingCreateRequest request) {
        if (request.listingId() != null) {
            var found = listingRepository.findById(request.listingId());
            if (found.isPresent()) {
                return found.get();
            }
        }

        if (request.homeownerId() != null) {
            var owned = listingRepository.findByHomeownerId(request.homeownerId()).stream().findFirst();
            if (owned.isPresent()) {
                return owned.get();
            }

            Homeowner owner = homeownerRepository.findById(request.homeownerId())
                    .orElseThrow(() -> new IllegalArgumentException("Homeowner not found"));
            LocalDateTime stayStart = request.startDate() != null ? request.startDate() : LocalDateTime.now();
            LocalDateTime stayEnd = request.endDate() != null ? request.endDate() : stayStart.plusDays(1);

            String place = listingPlace(owner);
            Listing created = new Listing();
            created.setHomeowner(owner);
            created.setSuburb(place);
            created.setExactAddress(place);
            created.setHomeDetails(listingDetails(owner));
            created.setDescription("Booking stay");
            created.setStatus("OPEN");
            created.setStartDate(stayStart);
            created.setEndDate(stayEnd);
            return listingRepository.save(created);
        }

        return listingRepository.findAll().stream().findFirst()
                .orElseThrow(() -> new IllegalStateException("No listings exist in the database."));
    }

    private String listingPlace(Homeowner owner) {
        String place = owner.getAddress();
        if (place == null || place.isBlank()) {
            return "Home";
        }
        place = place.trim();
        return place.length() > 255 ? place.substring(0, 255) : place;
    }

    private String listingDetails(Homeowner owner) {
        String details = owner.getRequirements();
        if (details == null || details.isBlank()) {
            return "Home stay";
        }
        details = details.trim();
        return details.length() > 255 ? details.substring(0, 255) : details;
    }

    private BookingOfferResponse mapOffer(BookingOffer offer) {
        Sitter s = offer.getSitter();
        return new BookingOfferResponse(
                s.getId(),
                s.getUser() != null ? s.getUser().getName() : "Sitter",
                s.getRating(),
                s.getTotalReviews(),
                offer.getPricePerNight(),
                offer.getPricePerVisit(),
                offer.getPricePerWalk(),
                offer.getCreatedAt());
    }

    private BookingResponse mapToDTO(Booking booking) {
        return mapToDTO(booking, null);
    }

    private static String firstName(String name) {
        if (name == null || name.isBlank()) return "Homeowner";
        return name.trim().split("\\s+")[0];
    }

    /** A readable name for a booking type such as "Stay Night & Walk Dog". */
    private static String serviceSummary(String bookingType) {
        String t = bookingType == null ? "" : bookingType.toUpperCase();
        if (t.contains("NIGHT")) return "Overnight Stay";
        if (t.contains("DROP") || t.contains("VISIT") || t.contains("FEED")) return "Drop-in Visits";
        if (t.contains("WALK")) return "Dog Walks";
        return "Pet Sitting";
    }

    /** " (12 Mar - 15 Mar)", or empty when the dates are missing. */
    private static String dateRange(Booking booking) {
        if (booking.getStartDate() == null || booking.getEndDate() == null) return "";
        var fmt = java.time.format.DateTimeFormatter.ofPattern("d MMM");
        return " (" + booking.getStartDate().format(fmt) + " - " + booking.getEndDate().format(fmt) + ")";
    }

    /** viewerSitterId: when a sitter is looking, only their own offer is included. */
    private BookingResponse mapToDTO(Booking booking, Integer viewerSitterId) {
        var homeowner = booking.getListing() != null ? booking.getListing().getHomeowner() : null;
        var sitter = booking.getSitter();

        // Null while the booking is open, so the app can show "looking for a sitter".
        String sitterName = sitter == null ? null
                : sitter.getUser() != null ? sitter.getUser().getName() : "Sitter";
        String homeownerName = homeowner != null && homeowner.getUser() != null
                ? homeowner.getUser().getName() : "Homeowner";
        // e.g. "Sarah's Overnight Stay" rather than a listing number.
        String listingTitle = firstName(homeownerName) + "'s " + serviceSummary(booking.getBookingType());

        List<BookingOfferResponse> offers = offerRepository.findByBookingIdOrderByCreatedAtAsc(booking.getId()).stream()
                .filter(o -> viewerSitterId == null || viewerSitterId.equals(o.getSitter().getId()))
                .map(this::mapOffer)
                .collect(Collectors.toList());

        return new BookingResponse(
                booking.getId(),
                booking.getListing() != null ? booking.getListing().getId() : null,
                listingTitle,
                sitter != null ? sitter.getId() : null,
                sitterName,
                homeowner != null ? homeowner.getId() : null,
                homeownerName,
                booking.getBookingType(),
                booking.getStartDate(),
                booking.getEndDate(),
                booking.getNotes(),
                booking.getStatus(),
                booking.getConfirmedAt(),
                booking.getPricePerNight(),
                booking.getPricePerVisit(),
                booking.getPricePerWalk(),
                offers,
                reviewRepository.existsByBookingIdAndReviewedByIgnoreCase(booking.getId(), "HOMEOWNER"),
                reviewRepository.existsByBookingIdAndReviewedByIgnoreCase(booking.getId(), "SITTER")
        );
    }

    /**
     * The booking as one sitter's offer shows it in chat: that sitter, their prices and the status
     * REQUESTED, which the chat reads as "waiting for the homeowner to accept".
     */
    private BookingResponse mapOfferToDTO(BookingOffer offer) {
        Booking b = offer.getBooking();
        BookingResponse base = mapToDTO(b, offer.getSitter().getId());
        BookingOfferResponse o = mapOffer(offer);
        return new BookingResponse(
                base.id(), base.listingId(), base.listingTitle(),
                o.sitterId(), o.sitterName(),
                base.homeownerId(), base.homeownerName(),
                base.bookingType(), base.startDate(), base.endDate(), base.notes(),
                "REQUESTED", base.confirmedAt(),
                o.pricePerNight(), o.pricePerVisit(), o.pricePerWalk(),
                base.offers(), base.homeownerReviewed(), base.sitterReviewed());
    }
}
