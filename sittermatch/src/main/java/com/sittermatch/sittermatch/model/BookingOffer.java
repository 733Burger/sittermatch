package com.sittermatch.sittermatch.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/**
 * A sitter offering to take a pending booking, with their prices. A booking can have offers from
 * several sitters; the homeowner accepts one and the others are deleted.
 */
@Entity
@Table(name = "booking_offers",
        uniqueConstraints = @UniqueConstraint(columnNames = {"booking_id", "sitter_id"}))
public class BookingOffer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "booking_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Booking booking;

    @ManyToOne
    @JoinColumn(name = "sitter_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Sitter sitter;

    @Column(name = "price_per_night", precision = 10, scale = 2)
    private BigDecimal pricePerNight;

    @Column(name = "price_per_visit", precision = 10, scale = 2)
    private BigDecimal pricePerVisit;

    @Column(name = "price_per_walk", precision = 10, scale = 2)
    private BigDecimal pricePerWalk;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public BookingOffer() {}

    public BookingOffer(Booking booking, Sitter sitter) {
        this.booking = booking;
        this.sitter = sitter;
        this.createdAt = LocalDateTime.now();
    }

    public Integer getId() { return id; }
    public Booking getBooking() { return booking; }
    public Sitter getSitter() { return sitter; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    public BigDecimal getPricePerNight() { return pricePerNight; }
    public void setPricePerNight(BigDecimal pricePerNight) { this.pricePerNight = pricePerNight; }

    public BigDecimal getPricePerVisit() { return pricePerVisit; }
    public void setPricePerVisit(BigDecimal pricePerVisit) { this.pricePerVisit = pricePerVisit; }

    public BigDecimal getPricePerWalk() { return pricePerWalk; }
    public void setPricePerWalk(BigDecimal pricePerWalk) { this.pricePerWalk = pricePerWalk; }
}
