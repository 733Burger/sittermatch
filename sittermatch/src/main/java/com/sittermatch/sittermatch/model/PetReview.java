package com.sittermatch.sittermatch.model;

public class PetReview {
    private int ID;
    private Booking booking_ID;
    private Pets pet_ID;
    private int rating;
    private String notes;

    public PetReview() {}

    public PetReview(int ID, Booking booking_ID, Pets pet_ID, int rating, String notes) {
        this.ID = ID;
        this.booking_ID = booking_ID;
        this.pet_ID = pet_ID;
        this.rating = rating;
        this.notes = notes;
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

    public Pets getPet_ID() {
        return pet_ID;
    }

    public void setPet_ID(Pets pet_ID) {
        this.pet_ID = pet_ID;
    }

    public int getRating() {
        return rating;
    }

    public void setRating(int rating) {
        this.rating = rating;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }
}
