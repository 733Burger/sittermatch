package com.sittermatch.sittermatch.controller;


import com.sittermatch.sittermatch.dto.BookingCreateRequest;
import com.sittermatch.sittermatch.dto.BookingResponseDTO;
import com.sittermatch.sittermatch.services.BookingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bookings")
@CrossOrigin(origins = "*")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @GetMapping
    public ResponseEntity<List<BookingResponseDTO>> getAllBookings() {
        return ResponseEntity.ok(bookingService.getAllBookings());
    }

    @GetMapping("/sitter/{sitterId}")
    public ResponseEntity<List<BookingResponseDTO>> getSitterBookings(@PathVariable Integer sitterId) {
        return ResponseEntity.ok(bookingService.getBookingsForSitter(sitterId));
    }

    @GetMapping("/homeowner/{homeownerId}")
    public ResponseEntity<List<BookingResponseDTO>> getHomeownerBookings(@PathVariable Integer homeownerId) {
        return ResponseEntity.ok(bookingService.getBookingsForHomeowner(homeownerId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookingResponseDTO> getBookingById(@PathVariable Integer id) {
        return bookingService.getBookingById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/create")
    public ResponseEntity<BookingResponseDTO> createBooking(@RequestBody BookingCreateRequest request) {
        return ResponseEntity.ok(bookingService.createBooking(request));
    }

    @PostMapping("/dispatch")
    public ResponseEntity<BookingResponseDTO> dispatchBooking(@RequestBody BookingCreateRequest request) {
        return ResponseEntity.ok(bookingService.createBooking(request));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<BookingResponseDTO> updateStatus(
            @PathVariable Integer id,
            @RequestParam String status) {
        return ResponseEntity.ok(bookingService.updateBookingStatus(id, status));
    }
}