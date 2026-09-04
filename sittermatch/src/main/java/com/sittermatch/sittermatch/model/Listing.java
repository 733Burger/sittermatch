package com.sittermatch.sittermatch.model;

import java.time.LocalDate;

public class Listing {
    private int ID;
    private Homeowner homeowner_ID;
    private String suburb;
    private String description;
    private String home_details;
    private String exact_address;
    private LocalDate start_date;
    private LocalDate end_date;
    private String status;

    public Listing() {}

    public Listing(int ID, Homeowner homeowner_ID, String suburb, String description, String home_details, String exact_address, LocalDate start_date, LocalDate end_date, String status) {
        this.ID = ID;
        this.homeowner_ID = homeowner_ID;
        this.suburb = suburb;
        this.description = description;
        this.home_details = home_details;
        this.exact_address = exact_address;
        this.start_date = start_date;
        this.end_date = end_date;
        this.status = status;
    }

    public int getId() {
        return ID;
    }

    public void setId(int ID) {
        this.ID = ID;
    }

    public Homeowner getHomeowner_ID() {
        return homeowner_ID;
    }

    public void setHomeowner_ID(Homeowner homeowner_ID) {
        this.homeowner_ID = homeowner_ID;
    }

    public String getSuburb() {
        return suburb;
    }

    public void setSuburb(String suburb) {
        this.suburb = suburb;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getHome_details() {
        return home_details;
    }

    public void setHome_details(String home_details) {
        this.home_details = home_details;
    }

    public String getExact_address() {
        return exact_address;
    }

    public void setExact_address(String exact_address) {
        this.exact_address = exact_address;
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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
