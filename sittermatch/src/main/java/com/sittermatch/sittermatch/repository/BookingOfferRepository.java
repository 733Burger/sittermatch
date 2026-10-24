package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.BookingOffer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BookingOfferRepository extends JpaRepository<BookingOffer, Integer> {
    List<BookingOffer> findByBookingIdOrderByCreatedAtAsc(Integer bookingId);
    Optional<BookingOffer> findByBookingIdAndSitterId(Integer bookingId, Integer sitterId);
    List<BookingOffer> findBySitterId(Integer sitterId);
}
