package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.BookingDismissal;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookingDismissalRepository extends JpaRepository<BookingDismissal, Integer> {
    boolean existsByBookingIdAndSitterId(Integer bookingId, Integer sitterId);
}
