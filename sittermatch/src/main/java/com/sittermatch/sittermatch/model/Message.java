package com.sittermatch.sittermatch.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "sitter_id", nullable = false)
    private Sitter sitter;

    @ManyToOne
    @JoinColumn(name = "homeowner_id", nullable = false)
    private Homeowner homeowner;

    @Column(name = "sent_by", nullable = false)
    private String sentBy; // "sitter" or "homeowner"

    private String message;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "is_read")
    private Boolean isRead = false;

    public Message() {}

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Sitter getSitter() { return sitter; }
    public void setSitter(Sitter sitter) { this.sitter = sitter; }

    public Homeowner getHomeowner() { return homeowner; }
    public void setHomeowner(Homeowner homeowner) { this.homeowner = homeowner; }

    public String getSentBy() { return sentBy; }
    public void setSentBy(String sentBy) { this.sentBy = sentBy; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public LocalDateTime getSentAt() { return sentAt; }
    public void setSentAt(LocalDateTime sentAt) { this.sentAt = sentAt; }

    public Boolean getIsRead() { return isRead; }
    public void setIsRead(Boolean isRead) { this.isRead = isRead; }
}