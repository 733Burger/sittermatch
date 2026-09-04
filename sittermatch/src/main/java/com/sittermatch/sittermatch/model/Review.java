package com.sittermatch.sittermatch.model;

public class Review {
    private int ID;
    private Booking booking_ID;
    private Sitter sitter_ID;
    private Homeowner homeowner_ID;
    private int rating;
    private String comments;
    private String status;

    public Review() {}

    public Review(int ID, Booking booking_ID, Sitter sitter_ID, Homeowner homeowner_ID, int rating, String comments, String status) {
        this.ID = ID;
        this.booking_ID = booking_ID;
        this.sitter_ID = sitter_ID;
        this.homeowner_ID = homeowner_ID;
        this.rating = rating;
        this.comments = comments;
        this.status = status;
    }

    public int getId() {
        return ID;
    }

    public void setId(int ID) {
        this.ID = ID;
    }

    public Booking getBooking_ID() {
        return booking_ID;
    }

    public void setBooking_ID(Booking booking_ID) {
        this.booking_ID = booking_ID;
    }

    public Sitter getSitter_ID() {
        return sitter_ID;
    }

    public void setSitter_ID(Sitter sitter_ID) {
        this.sitter_ID = sitter_ID;
    }

    public Homeowner getHomeowner_ID() {
        return homeowner_ID;
    }

    public void setHomeowner_ID(Homeowner homeowner_ID) {
        this.homeowner_ID = homeowner_ID;
    }

    public int getRating() {
        return rating;
    }

    public void setRating(int rating) {
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
