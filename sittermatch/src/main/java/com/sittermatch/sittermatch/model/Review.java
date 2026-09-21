package com.sittermatch.sittermatch.model;


import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "reviews")
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "booking_id")
    private Booking booking;

    @ManyToOne
    @JoinColumn(name = "sitter_id")
    private Sitter sitter;

    @ManyToOne
    @JoinColumn(name = "homeowner_id")
    private Homeowner homeowner;

    private Integer rating;
    private String comments;
    private String status;

    public Review() {}

    public Review(Integer id, Booking booking, Sitter sitter, Homeowner homeowner, Integer rating, String comments,
            String status) {
        this.id = id;
        this.booking = booking;
        this.sitter = sitter;
        this.homeowner = homeowner;
        this.rating = rating;
        this.comments = comments;
        this.status = status;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Booking getBooking() {
        return booking;
    }

    public void setBooking(Booking booking) {
        this.booking = booking;
    }

    public Sitter getSitter() {
        return sitter;
    }

    public void setSitter(Sitter sitter) {
        this.sitter = sitter;
    }

    public Homeowner getHomeowner() {
        return homeowner;
    }

    public void setHomeowner(Homeowner homeowner) {
        this.homeowner = homeowner;
    }

    public Integer getRating() {
        return rating;
    }

    public void setRating(Integer rating) {
        this.rating = rating;
    }

    public String getComments() {
        return comments;
    }

    public void setComments(String comments) {
        this.comments = comments;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    

    
}
