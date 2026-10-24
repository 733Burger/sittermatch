package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.BookingTaskCheck;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface BookingTaskCheckRepository extends JpaRepository<BookingTaskCheck, Integer> {
    List<BookingTaskCheck> findByBookingIdAndCheckDate(Integer bookingId, LocalDate checkDate);

    Optional<BookingTaskCheck> findByBookingIdAndTaskIdAndCheckDate(Integer bookingId, Integer taskId, LocalDate checkDate);
}
