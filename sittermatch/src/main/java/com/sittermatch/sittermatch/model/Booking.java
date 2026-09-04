package com.sittermatch.sittermatch.model;
import java.time.LocalDate;

public class Booking {
    private int ID;
    private Listing listing_ID;
    private Sitter sitter_ID;
    private String booking_type;
    private LocalDate start_date;
    private LocalDate end_date;
    private String notes;
    private String status;
    private LocalDate confirmed_at;

    public Booking() {}

    public Booking(int ID, Listing listing_ID, Sitter sitter_ID, String booking_type, LocalDate start_date, LocalDate end_date, String notes, String status, LocalDate confirmed_at) {
        this.ID = ID;
        this.listing_ID = listing_ID;
        this.sitter_ID = sitter_ID;
        this.booking_type = booking_type;
        this.start_date = start_date;
        this.end_date = end_date;
        this.notes = notes;
        this.status = status;
        this.confirmed_at = confirmed_at;
    }

    public int getId() {
        return ID;
    }

    public void setId(int ID) {
        this.ID = ID;
    }

    public Listing getListing_ID() {
        return listing_ID;
    }

    public void setListing_ID(Listing listing_ID) {
        this.listing_ID = listing_ID;
    }

    public Sitter getSitter_ID() {
        return sitter_ID;
    }

    public void setSitter_ID(Sitter sitter_ID) {
        this.sitter_ID = sitter_ID;
    }

    public String getBooking_type() {
        return booking_type;
    }

    public void setBooking_type(String booking_type) {
        this.booking_type = booking_type;
    }

    public LocalDate getStart_date() {
        return start_date;
    }

    public void setStart_date(LocalDate start_date) {
        this.start_date = start_date;
    }

    public LocalDate getEnd_date() {
        return end_date;
    }

    public void setEnd_date(LocalDate end_date) {
        this.end_date = end_date;
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

    public LocalDate getConfirmed_at() {
        return confirmed_at;
    }

    public void setConfirmed_at(LocalDate confirmed_at) {
        this.confirmed_at = confirmed_at;
    }
}
