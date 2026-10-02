package com.sittermatch.sittermatch.model;

import jakarta.persistence.*;

@Entity
@Table(name = "sitter_checks")
public class SitterCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "sitter_id", nullable = false)
    private Integer sitterId;

    @Column(nullable = false, length = 50)
    private String type;

    // ESCAPED RESERVED WORD WITH BACKTICKS
    @Column(name = "`references`", columnDefinition = "TEXT")
    private String references;

    @Column(name = "id_photo", length = 500)
    private String idPhoto;

    @Column(nullable = false, length = 20)
    private String status = "none"; // 'none', 'pending', 'verified'

    public SitterCheck() {}

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getSitterId() { return sitterId; }
    public void setSitterId(Integer sitterId) { this.sitterId = sitterId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getReferences() { return references; }
    public void setReferences(String references) { this.references = references; }

    public String getIdPhoto() { return idPhoto; }
    public void setIdPhoto(String idPhoto) { this.idPhoto = idPhoto; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}