package com.sittermatch.sittermatch.model;

public class Homeowner {
    private int ID;
    private User user_ID;
    private Boolean is_verified;
    private String requirements;
    private String service_required;
    private double rating;
    private int total_reviews;

    public Homeowner() {}

    public Homeowner(int ID, User user_ID, Boolean is_verified, String requirements, String service_required, double rating, int total_reviews) {
        this.ID = ID;
        this.user_ID = user_ID;
        this.is_verified = is_verified;
        this.requirements = requirements;
        this.service_required = service_required;
        this.rating = rating;
        this.total_reviews = total_reviews;
    }

    public int getId() {
        return ID;
    }
    
    public void setId(int ID) {
        this.ID = ID;
    }

    public User getUser_ID() {
        return user_ID;
    }

    public void setUser_ID(User user_ID) {
        this.user_ID = user_ID;
    }

    public Boolean getIs_verified() {
        return is_verified;
    }

    public void setIs_verified(Boolean is_verified) {
        this.is_verified = is_verified;
    }

    public String getRequirements() {
        return requirements;
    }

    public void setRequirements(String requirements) {
        this.requirements = requirements;
    }

    public String getService_required() {
        return service_required;
    }

    public void setService_required(String service_required) {
        this.service_required = service_required;
    }

    public double getRating() {
        return rating;
    }

    public void setRating(double rating) {
        this.rating = rating;
    }

    public int getTotal_reviews() {
        return total_reviews;
    }

    public void setTotal_reviews(int total_reviews) {
        this.total_reviews = total_reviews;
    }
}
