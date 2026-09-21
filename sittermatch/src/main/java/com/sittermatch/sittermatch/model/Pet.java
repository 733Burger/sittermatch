package com.sittermatch.sittermatch.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "pets")
public class Pet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

   @ManyToOne
    @JoinColumn(name = "homeowner_id", nullable = false)
    private Homeowner homeowner;

    private String name;
    private String species;
    private String breed;
    private Integer age;

    @Column(name = "care_notes")
    private String careNotes;

    @Column(name = "behaviour_score")
    private Double behaviourScore;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "total_reviews")
    private Integer totalReviews;

    public Pet() {}

    public Pet(Integer id, Homeowner homeowner, String name, String species, String breed, Integer age,
            String careNotes, Double behaviourScore, String imageUrl, Integer totalReviews) {
        this.id = id;
        this.homeowner = homeowner;
        this.name = name;
        this.species = species;
        this.breed = breed;
        this.age = age;
        this.careNotes = careNotes;
        this.behaviourScore = behaviourScore;
        this.imageUrl = imageUrl;
        this.totalReviews = totalReviews;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Homeowner getHomeowner() {
        return homeowner;
    }

    public void setHomeowner(Homeowner homeowner) {
        this.homeowner = homeowner;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSpecies() {
        return species;
    }

    public void setSpecies(String species) {
        this.species = species;
    }

    public String getBreed() {
        return breed;
    }

    public void setBreed(String breed) {
        this.breed = breed;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public String getCareNotes() {
        return careNotes;
    }

    public void setCareNotes(String careNotes) {
        this.careNotes = careNotes;
    }

    public Double getBehaviourScore() {
        return behaviourScore;
    }

    public void setBehaviourScore(Double behaviourScore) {
        this.behaviourScore = behaviourScore;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Integer getTotalReviews() {
        return totalReviews;
    }

    public void setTotalReviews(Integer totalReviews) {
        this.totalReviews = totalReviews;
    }

    


    
}
