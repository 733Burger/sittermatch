package com.sittermatch.sittermatch.services;

import com.sittermatch.sittermatch.dto.BookingCreateRequest;
import com.sittermatch.sittermatch.dto.BookingResponseDTO;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Listing;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.repository.BookingRepository;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.ListingRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import org.springframework.stereotype.Service;

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

    public BookingService(BookingRepository bookingRepository,
                          ListingRepository listingRepository,
                          SitterRepository sitterRepository,
                          HomeownerRepository homeownerRepository) {
        this.bookingRepository = bookingRepository;
        this.listingRepository = listingRepository;
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
    }

    public List<BookingResponseDTO> getAllBookings() {
        return bookingRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<BookingResponseDTO> getBookingsForSitter(Integer sitterId) {
        return bookingRepository.findBySitterId(sitterId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<BookingResponseDTO> getBookingsForHomeowner(Integer homeownerId) {
        return bookingRepository.findByListingHomeownerId(homeownerId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public Optional<BookingResponseDTO> getBookingById(Integer id) {
        return bookingRepository.findById(id).map(this::mapToDTO);
    }

 public BookingResponseDTO createBooking(BookingCreateRequest request) {
        Listing listing = resolveListing(request);

        // Find requested sitter ID, or fallback to the first available in DB
        Sitter sitter = (request.sitterId() != null 
                ? sitterRepository.findById(request.sitterId()) 
                : java.util.Optional.<Sitter>empty())
                .or(() -> sitterRepository.findAll().stream().findFirst())
                .orElseThrow(() -> new IllegalStateException("No sitters exist in the database."));

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

    public BookingResponseDTO updateBookingStatus(Integer bookingId, String newStatus) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with ID: " + bookingId));

        booking.setStatus(newStatus.toUpperCase());
        if ("CONFIRMED".equalsIgnoreCase(newStatus) || "ACCEPTED".equalsIgnoreCase(newStatus)) {
            booking.setConfirmedAt(LocalDateTime.now());
        }

        Booking updated = bookingRepository.save(booking);
        return mapToDTO(updated);
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

    private BookingResponseDTO mapToDTO(Booking booking) {
        String listingTitle = booking.getListing() != null 
                ? "Listing #" + booking.getListing().getId() 
                : "Listing";

        String sitterName = booking.getSitter() != null 
                ? "Sitter #" + booking.getSitter().getId() 
                : "Assigned Sitter";

        return new BookingResponseDTO(
                booking.getId(),
                booking.getListing() != null ? booking.getListing().getId() : null,
                listingTitle,
                booking.getSitter() != null ? booking.getSitter().getId() : null,
                sitterName,
                booking.getBookingType(),
                booking.getStartDate(),
                booking.getEndDate(),
                booking.getNotes(),
                booking.getStatus(),
                booking.getConfirmedAt()
        );
    }
}


