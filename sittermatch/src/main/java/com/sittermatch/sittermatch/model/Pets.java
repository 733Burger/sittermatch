package com.sittermatch.sittermatch.model;

public class Pets {
    private int ID;
    private Homeowner homeowner_ID;
    private String name;
    private String species;
    private String breed;
    private int age;
    private String care_notes;
    private int behavior_score;
    private String image_url;

    public Pets() {}

    public Pets(int ID, Homeowner homeowner_ID, String name, String species, String breed, int age, String care_notes, int behavior_score, String image_url) {
        this.ID = ID;
        this.homeowner_ID = homeowner_ID;
        this.name = name;
        this.species = species;
        this.breed = breed;
        this.age = age;
        this.care_notes = care_notes;
        this.behavior_score = behavior_score;
        this.image_url = image_url;
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

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public String getCare_notes() {
        return care_notes;
    }

    public void setCare_notes(String care_notes) {
        this.care_notes = care_notes;
    }

    public int getBehavior_score() {
        return behavior_score;
    }

    public void setBehavior_score(int behavior_score) {
        this.behavior_score = behavior_score;
    }

    public String getImage_url() {
        return image_url;
    }

    public void setImage_url(String image_url) {
        this.image_url = image_url;
    }
}
