package com.sittermatch.sittermatch.model;

import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;


@Entity
@Table(name = "sitters")
public class Sitter {

    @Id
    private Integer id;

    @OneToOne
    @MapsId
    @JoinColumn(name = "id")
    private User user;

    @Column(name = "is_verified")
    private Boolean isVerified;

    @ElementCollection(targetClass = PetType.class)
    @CollectionTable(name = "sitter_pet_preferences", joinColumns = @JoinColumn(name = "sitter_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "pet_type")
    private Set<PetType> petPreferences;

    private String experience;

    @ElementCollection(targetClass = ServiceType.class)
    @CollectionTable(name = "sitter_services", joinColumns = @JoinColumn(name = "sitter_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "service_type")
    private Set<ServiceType> services;

    @Column(name = "day_rate")
    private Double dayRate;

    @Column(name = "night_rate")
    private Double nightRate;

    private Double rating;

    @Column(name = "total_review")
    private Integer totalReviews;

    public Sitter() {}

    public Sitter(Integer id, User user, Boolean isVerified, Set<PetType> petPreferences, String experience,
            Set<ServiceType> services, Double dayRate, Double nightRate, Double rating, Integer totalReviews) {
        this.id = id;
        this.user = user;
        this.isVerified = isVerified;
        this.petPreferences = petPreferences;
        this.experience = experience;
        this.services = services;
        this.dayRate = dayRate;
        this.nightRate = nightRate;
        this.rating = rating;
        this.totalReviews = totalReviews;
    }

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

    public Boolean getIsVerified() {
        return isVerified;
    }

    public void setIsVerified(Boolean isVerified) {
        this.isVerified = isVerified;
    }

    public Set<PetType> getPetPreferences() {
        return petPreferences;
    }

    public void setPetPreferences(Set<PetType> petPreferences) {
        this.petPreferences = petPreferences;
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

    

    
}


