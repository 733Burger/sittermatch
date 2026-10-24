package com.sittermatch.sittermatch.model;

import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/** One item on a homeowner's stay checklist, e.g. "Morning feed". Every booking of theirs uses it. */
@Entity
@Table(name = "homeowner_tasks")
public class HomeownerTask {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "homeowner_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Homeowner homeowner;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(length = 255)
    private String note;

    public HomeownerTask() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Homeowner getHomeowner() { return homeowner; }
    public void setHomeowner(Homeowner homeowner) { this.homeowner = homeowner; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
