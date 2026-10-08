package com.sittermatch.sittermatch.model;

import jakarta.persistence.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "sitters")
public class Sitter {

    @Id
    private Integer id;

    @OneToOne
    @MapsId
    @JoinColumn(name = "id")
    private User user;

    private Integer experience;

    @Column(name = "day_rate")
    private Double dayRate;

    @Column(name = "night_rate")
    private Double nightRate;

    private Double rating = 0.0;

    @Column(name = "total_reviews")
    private Integer totalReviews = 0;

    @Column(name = "is_verified")
    private Boolean isVerified = false;

    @ElementCollection
    @CollectionTable(name = "sitter_service_types", joinColumns = @JoinColumn(name = "sitter_id"))
    @Column(name = "service_type")
    private Set<String> serviceTypes = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "sitter_pet_types", joinColumns = @JoinColumn(name = "sitter_id"))
    @Column(name = "pet_type")
    private Set<String> petTypes = new HashSet<>();

    // Default constructor
    public Sitter() {
    }

    // Constructor
    public Sitter(
            Integer id,
            User user,
            Integer experience,
            Double dayRate,
            Double nightRate,
            Double rating,
            Integer totalReviews,
            Boolean isVerified) {
        this.id = id;
        this.user = user;
        this.experience = experience;
        this.dayRate = dayRate;
        this.nightRate = nightRate;
        this.rating = rating;
        this.totalReviews = totalReviews;
        this.isVerified = isVerified;
    }

    // Getters and Setters

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Integer getExperience() {
        return experience;
    }

    public void setExperience(Integer experience) {
        this.experience = experience;
    }

    public Double getDayRate() {
        return dayRate;
    }

    public void setDayRate(Double dayRate) {
        this.dayRate = dayRate;
    }

    public Double getNightRate() {
        return nightRate;
    }

    public void setNightRate(Double nightRate) {
        this.nightRate = nightRate;
    }

    public Double getRating() {
        return rating;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public Integer getTotalReviews() {
        return totalReviews;
    }

    public void setTotalReviews(Integer totalReviews) {
        this.totalReviews = totalReviews;
    }

    public Boolean getIsVerified() {
        return isVerified;
    }

    public void setIsVerified(Boolean isVerified) {
        this.isVerified = isVerified;
    }

    public Set<String> getServiceTypes() {
        return serviceTypes;
    }

    public void setServiceTypes(Set<String> serviceTypes) {
        this.serviceTypes = serviceTypes;
    }

    public Set<String> getPetTypes() {
        return petTypes;
    }

    public void setPetTypes(Set<String> petTypes) {
        this.petTypes = petTypes;
    }
}
