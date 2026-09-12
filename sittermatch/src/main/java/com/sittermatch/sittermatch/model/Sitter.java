package com.sittermatch.sittermatch.model;

import java.util.Set;

public class Sitter {
    private int ID;
    private Boolean is_verified;
    private Set<PetType> pet_preferences;
    private String experience;
    private Set<ServiceType> services;
    private double day_rate;
    private double night_rate;
    private double rating;
    private int total_reviews;

    public Sitter() {}

    public Sitter(int ID, Boolean is_verified, Set<PetType> pet_preferences, String experience, Set<ServiceType> services, double day_rate, double night_rate, double rating, int total_reviews) {
        this.ID = ID;
        this.is_verified = is_verified;
        this.pet_preferences = pet_preferences;
        this.experience = experience;
        this.services = services;
        this.day_rate = day_rate;
        this.night_rate = night_rate;
        this.rating = rating;
        this.total_reviews = total_reviews;
    }

    public int getId() {
        return ID;
    }

    public void setId(int ID) {
        this.ID = ID;
    }

    public Boolean getIs_verified() {
        return is_verified;
    }

    public void setIs_verified(Boolean is_verified) {
        this.is_verified = is_verified;
    }

    public Set<PetType> getPet_preferences() {
        return pet_preferences;
    }

    public void setPet_preferences(Set<PetType> pet_preferences) {
        this.pet_preferences = pet_preferences;
    }

    public String getExperience() {
        return experience;
    }

    public void setExperience(String experience) {
        this.experience = experience;
    }

    public Set<ServiceType> getServices() {
        return services;
    }

    public void setServices(Set<ServiceType> services) {
        this.services = services;
    }

    public double getDay_rate() {
        return day_rate;
    }

    public void setDay_rate(double day_rate) {
        this.day_rate = day_rate;
    }

    public double getNight_rate() {
        return night_rate;
    }

    public void setNight_rate(double night_rate) {
        this.night_rate = night_rate;
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


