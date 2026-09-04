package com.sittermatch.sittermatch.model;

import java.time.LocalDateTime;

public class Messages {
    private int ID;
    private String booking_id;
    private User sender_id;
    private User receiver_id;
    private String message;
    private LocalDateTime sent_at;

    public Messages() {}

    public Messages(int ID, String booking_id, User sender_id, User receiver_id, String message, LocalDateTime sent_at) {
        this.ID = ID;
        this.booking_id = booking_id;
        this.sender_id = sender_id;
        this.receiver_id = receiver_id;
        this.message = message;
        this.sent_at = sent_at;
    }

    public int getId() {
        return ID;
    }

    public void setId(int ID) {
        this.ID = ID;
    }

    public String getBooking_id() {
        return booking_id;
    }

    public void setBooking_id(String booking_id) {
        this.booking_id = booking_id;
    }

    public User getSender_id() {
        return sender_id;
    }

    public void setSender_id(User sender_id) {
        this.sender_id = sender_id;
    }

    public User getReceiver_id() {
        return receiver_id;
    }

    public void setReceiver_id(User receiver_id) {
        this.receiver_id = receiver_id;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LocalDateTime getSent_at() {
        return sent_at;
    }

    public void setSent_at(LocalDateTime sent_at) {
        this.sent_at = sent_at;
    }
}
