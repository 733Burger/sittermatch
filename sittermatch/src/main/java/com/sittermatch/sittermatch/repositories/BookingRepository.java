package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.Booking;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookingRepository extends JpaRepository<Booking, Integer> {

    // Find all bookings for a specific sitter
    List<Booking> findBySitterId(Integer sitterId);

    // Find all bookings for a specific listing
    List<Booking> findByListingId(Integer listingId);

    // Find all bookings belonging to a specific homeowner through the listing relationship
    List<Booking> findByListingHomeownerId(Integer homeownerId);

    // Find bookings by status (e.g., "PENDING", "CONFIRMED", "CANCELLED", "COMPLETED")
    List<Booking> findByStatus(String status);

    // Find bookings for a sitter filtered by status
    List<Booking> findBySitterIdAndStatus(Integer sitterId, String status);
}
