package com.sittermatch.sittermatch.model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;

import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Entity
@Table(name = "sitters")
public class Sitter {
    @Id
    private Integer id;

    @OneToOne
    @MapsId
    @JoinColumn(name = "id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User user;

    @Column(name = "experience", columnDefinition = "TEXT")
    private String experience;

    @Column(name = "day_rate")
    private Double dayRate;

    @Column(name = "night_rate")
    private Double nightRate;

    private Double rating = 0.0;

    @Column(name = "total_reviews")
    private Integer totalReviews = 0;

    @Column(name = "is_verified")
    private Boolean isVerified = false;

    @Column(length = 100)
    private String suburb;

    @Column(length = 100)
    private String city;

    @Column(precision = 9, scale = 6)
    private BigDecimal latitude;
    
    @Column(precision = 9, scale = 6)
    private BigDecimal longitude;

    @ElementCollection 
    @CollectionTable (
        name = "sitter_services",
        joinColumns = @JoinColumn (name = "sitter_id", nullable = false)
    )
    private Set<SitterServices> services = new HashSet<>();

    @ElementCollection
    @CollectionTable (
        name = "sitter_pet_preferences",
        joinColumns = @JoinColumn (name = "sitter_id", nullable = false)
    )
    @Column(name = "pet_type", nullable = false, length = 45)
    private Set<String> petPreferences = new HashSet<>();

    public Sitter() {
    }

    public Sitter(
            Integer id,
            User user,
            String experience,
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

    public String getExperience() {
        return experience;
    }

    public void setExperience(String experience) {
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

    public Set<SitterServices> getServices() {
        return services;
    }

    public void setServices(Set<SitterServices> services) {
        this.services = services;
    }

    public Set<String> getPetPreferences() {
        return petPreferences;
    }

    public void setPetPreferences(Set<String> petPreferences) {
        this.petPreferences = petPreferences;
    }
}
