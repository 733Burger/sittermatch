package com.sittermatch.sittermatch.dto;

import java.util.Set;

public class SitterResponseDTO {
    private Integer id;
    private String name;
    private String email;
    private String phone;
    private Double rating;
    private Integer totalReviews;
    private Double dayRate;
    private Double nightRate;
    private Integer experience;
    private Set<String> serviceTypes;
    private Set<String> petTypes;
    private Boolean isVerified;

    public SitterResponseDTO() {}

    public SitterResponseDTO(Integer id, String name, String email, String phone, Double rating, 
                             Integer totalReviews, Double dayRate, Double nightRate, 
                             Integer experience, Set<String> serviceTypes, 
                             Set<String> petTypes, Boolean isVerified) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.phone = phone;
        this.rating = rating;
        this.totalReviews = totalReviews;
        this.dayRate = dayRate;
        this.nightRate = nightRate;
        this.experience = experience;
        this.serviceTypes = serviceTypes;
        this.petTypes = petTypes;
        this.isVerified = isVerified;
    }

    public Integer getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public Double getRating() { return rating; }
    public Integer getTotalReviews() { return totalReviews; }
    public Double getDayRate() { return dayRate; }
    public Double getNightRate() { return nightRate; }
    public Integer getExperience() { return experience; }
    public Set<String> getServiceTypes() { return serviceTypes; }
    public Set<String> getPetTypes() { return petTypes; }
    public Boolean getIsVerified() { return isVerified; }
}