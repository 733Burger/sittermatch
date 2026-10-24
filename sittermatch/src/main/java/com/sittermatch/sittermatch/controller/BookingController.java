package com.sittermatch.sittermatch.controller;


import com.sittermatch.sittermatch.dto.BookingCreateRequest;
import com.sittermatch.sittermatch.dto.BookingPricesRequest;
import com.sittermatch.sittermatch.dto.BookingResponse;
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
    public ResponseEntity<List<BookingResponse>> getAllBookings() {
        return ResponseEntity.ok(bookingService.getAllBookings());
    }

    @GetMapping("/sitter/{sitterId}")
    public ResponseEntity<List<BookingResponse>> getSitterBookings(@PathVariable Integer sitterId) {
        return ResponseEntity.ok(bookingService.getBookingsForSitter(sitterId));
    }

    @GetMapping("/homeowner/{homeownerId}")
    public ResponseEntity<List<BookingResponse>> getHomeownerBookings(@PathVariable Integer homeownerId) {
        return ResponseEntity.ok(bookingService.getBookingsForHomeowner(homeownerId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookingResponse> getBookingById(@PathVariable Integer id) {
        return bookingService.getBookingById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/create")
    public ResponseEntity<BookingResponse> createBooking(@RequestBody BookingCreateRequest request) {
        return ResponseEntity.ok(bookingService.createBooking(request));
    }

    @PostMapping("/dispatch")
    public ResponseEntity<BookingResponse> dispatchBooking(@RequestBody BookingCreateRequest request) {
        return ResponseEntity.ok(bookingService.createBooking(request));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(
            @PathVariable Integer id,
            @RequestParam String status) {
        try {
            return ResponseEntity.ok(bookingService.updateBookingStatus(id, status));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }

    /** Homeowner cancels a booking: it is deleted for good. */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBooking(@PathVariable Integer id) {
        return bookingService.deleteBooking(id)
                ? ResponseEntity.noContent().build()
                : ResponseEntity.notFound().build();
    }

    /** Open booking between a sitter and homeowner, or 204 if there is none (chat shows no booking card). */
    @GetMapping("/between")
    public ResponseEntity<BookingResponse> getBetween(@RequestParam Integer sitterId,
                                                    @RequestParam Integer homeownerId) {
        return bookingService.getActiveBookingBetween(sitterId, homeownerId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    /**
     * Sitter sends an offer on a pending booking and the homeowner gets a message. The optional body
     * holds prices for services the booking asks for that the sitter doesn't offer. Several sitters
     * can offer on an open booking; the homeowner accepts one.
     */
    @PostMapping("/{id}/request-accept")
    public ResponseEntity<?> requestAccept(@PathVariable Integer id,
                                           @RequestParam(required = false) Integer sitterId,
                                           @RequestBody(required = false) BookingPricesRequest extraPrices) {
        try {
            return ResponseEntity.ok(bookingService.requestAccept(id, sitterId, extraPrices));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }

    /** Sitter declines an open booking: hidden from them, still open for other sitters. */
    @PostMapping("/{id}/dismiss")
    public ResponseEntity<?> dismissOpenBooking(@PathVariable Integer id, @RequestParam Integer sitterId) {
        try {
            bookingService.dismissOpenBooking(id, sitterId);
            return ResponseEntity.noContent().build();
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }

    /** Homeowner accepts a sitter's offer. The other sitters' offers are removed. */
    @PostMapping("/{id}/offers/accept")
    public ResponseEntity<?> acceptOffer(@PathVariable Integer id, @RequestParam Integer sitterId) {
        try {
            return ResponseEntity.ok(bookingService.acceptOffer(id, sitterId));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }

    /** Homeowner turns down a sitter's offer, or the sitter withdraws it. */
    @PostMapping("/{id}/offers/decline")
    public ResponseEntity<?> declineOffer(@PathVariable Integer id, @RequestParam Integer sitterId) {
        try {
            bookingService.declineOffer(id, sitterId);
            return ResponseEntity.noContent().build();
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }

    /** Homeowner: change the prices in a sitter's offer. */
    @PatchMapping("/{id}/prices")
    public ResponseEntity<?> updatePrices(@PathVariable Integer id,
                                          @RequestParam(required = false) Integer sitterId,
                                          @RequestBody BookingPricesRequest request) {
        try {
            return ResponseEntity.ok(bookingService.updatePrices(id, sitterId, request));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }
}