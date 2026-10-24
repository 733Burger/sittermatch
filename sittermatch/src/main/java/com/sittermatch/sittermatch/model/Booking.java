package com.sittermatch.sittermatch.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "bookings")
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "listing_id", nullable = false)
    private Listing listing;

    // Null while the booking is open to any sitter; set when a sitter requests to accept it.
    @ManyToOne
    @JoinColumn(name = "sitter_id")
    private Sitter sitter;

    @Column(name = "booking_type", nullable = false)
    private String bookingType;

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    private String notes;

    private String status;

    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;

    @Column(name = "price_per_night", precision = 10, scale = 2)
    private BigDecimal pricePerNight;

    @Column(name = "price_per_visit", precision = 10, scale = 2)
    private BigDecimal pricePerVisit;

    @Column(name = "price_per_walk", precision = 10, scale = 2)
    private BigDecimal pricePerWalk;

    public BigDecimal getPricePerNight() { return pricePerNight; }
    public void setPricePerNight(BigDecimal v) { this.pricePerNight = v; }
    public BigDecimal getPricePerVisit() { return pricePerVisit; }
    public void setPricePerVisit(BigDecimal v) { this.pricePerVisit = v; }
    public BigDecimal getPricePerWalk() { return pricePerWalk; }
    public void setPricePerWalk(BigDecimal v) { this.pricePerWalk = v; }

    public Booking() {}

    public Booking(Integer id, Listing listing, Sitter sitter, String bookingType, LocalDateTime startDate,
            LocalDateTime endDate, String notes, String status, LocalDateTime confirmedAt) {
        this.id = id;
        this.listing = listing;
        this.sitter = sitter;
        this.bookingType = bookingType;
        this.startDate = startDate;
        this.endDate = endDate;
        this.notes = notes;
        this.status = status;
        this.confirmedAt = confirmedAt;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Listing getListing() {
        return listing;
    }

    public void setListing(Listing listing) {
        this.listing = listing;
    }

    public Sitter getSitter() {
        return sitter;
    }

    public void setSitter(Sitter sitter) {
        this.sitter = sitter;
    }

    public String getBookingType() {
        return bookingType;
    }

    public void setBookingType(String bookingType) {
        this.bookingType = bookingType;
    }

    public LocalDateTime getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDateTime startDate) {
        this.startDate = startDate;
    }

    public LocalDateTime getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDateTime endDate) {
        this.endDate = endDate;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(LocalDateTime confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    

    
}