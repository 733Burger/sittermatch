package com.sittermatch.sittermatch.model;

public class Sitter {
    private int ID;
    private User user_ID;
    private Boolean is_verified;
    private String pet_preferences;
    private String experience;
    private String services;
    private double rating;
    private int total_reviews;

    public Sitter() {}

    public Sitter(int ID, User user_ID, Boolean is_verified, String pet_preferences, String experience, String services, double rating, int total_reviews) {
        this.ID = ID;
        this.user_ID = user_ID;
        this.is_verified = is_verified;
        this.pet_preferences = pet_preferences;
        this.experience = experience;
        this.services = services;
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

    public String getPet_preferences() {
        return pet_preferences;
    }

    public void setPet_preferences(String pet_preferences) {
        this.pet_preferences = pet_preferences;
    }

    public String getExperience() {
        return experience;
    }

    public void setExperience(String experience) {
        this.experience = experience;
    }

    public String getServices() {
        return services;
    }

    public void setServices(String services) {
        this.services = services;
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


