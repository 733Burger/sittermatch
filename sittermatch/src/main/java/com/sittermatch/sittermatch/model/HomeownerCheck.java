package com.sittermatch.sittermatch.model;

import jakarta.persistence.*;

@Entity
@Table(name = "homeowner_checks")
public class HomeownerCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "homeowner_id", nullable = false)
    private Integer homeownerId;

    @Column(nullable = false, length = 50)
    private String type; // 'identity', 'proof_of_residence', 'emergency_contact'

    @Column(name = "text_details", columnDefinition = "TEXT")
    private String textDetails;

    @Column(name = "id_photo", length = 500)
    private String idPhoto;

    @Column(nullable = false, length = 20)
    private String status = "incomplete"; // 'incomplete', 'pending', 'completed'

    public HomeownerCheck() {}

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getHomeownerId() { return homeownerId; }
    public void setHomeownerId(Integer homeownerId) { this.homeownerId = homeownerId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTextDetails() { return textDetails; }
    public void setTextDetails(String textDetails) { this.textDetails = textDetails; }

    public String getIdPhoto() { return idPhoto; }
    public void setIdPhoto(String idPhoto) { this.idPhoto = idPhoto; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}