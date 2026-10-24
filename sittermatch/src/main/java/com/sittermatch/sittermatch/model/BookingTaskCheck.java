package com.sittermatch.sittermatch.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

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
import jakarta.persistence.UniqueConstraint;

/** A sitter ticking off one checklist task on one day of a booking. */
@Entity
@Table(name = "booking_task_checks",
        uniqueConstraints = @UniqueConstraint(columnNames = {"booking_id", "task_id", "check_date"}))
public class BookingTaskCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "booking_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Booking booking;

    @ManyToOne
    @JoinColumn(name = "task_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private HomeownerTask task;

    @Column(name = "check_date", nullable = false)
    private LocalDate checkDate;

    @Column(name = "checked_at", nullable = false)
    private LocalDateTime checkedAt;

    public BookingTaskCheck() {}

    public Integer getId() { return id; }
    public Booking getBooking() { return booking; }
    public void setBooking(Booking booking) { this.booking = booking; }
    public HomeownerTask getTask() { return task; }
    public void setTask(HomeownerTask task) { this.task = task; }
    public LocalDate getCheckDate() { return checkDate; }
    public void setCheckDate(LocalDate checkDate) { this.checkDate = checkDate; }
    public LocalDateTime getCheckedAt() { return checkedAt; }
    public void setCheckedAt(LocalDateTime checkedAt) { this.checkedAt = checkedAt; }
}
