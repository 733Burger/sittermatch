package com.sittermatch.sittermatch.model;

import jakarta.persistence.*;

@Entity
@Table(name = "saved_sitters")
public class SavedSitter {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "homeowner_id", nullable = false)
    private Integer homeownerId;

    @Column(name = "sitter_id", nullable = false)
    private Integer sitterId;

    public SavedSitter() {}

    public SavedSitter(Integer homeownerId, Integer sitterId) {
        this.homeownerId = homeownerId;
        this.sitterId = sitterId;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getHomeownerId() { return homeownerId; }
    public void setHomeownerId(Integer homeownerId) { this.homeownerId = homeownerId; }

    public Integer getSitterId() { return sitterId; }
    public void setSitterId(Integer sitterId) { this.sitterId = sitterId; }
}