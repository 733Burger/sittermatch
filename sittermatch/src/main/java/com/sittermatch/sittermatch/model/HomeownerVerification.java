package com.sittermatch.sittermatch.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "homeowner_verifications")
public class HomeownerVerification {

    @Id
    @Column(name = "homeowner_id")
    private Integer homeownerId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "homeowner_id")
    private Homeowner homeowner;

    @Column(name = "id_number_encrypted", nullable = false)
    private byte[] idNumberEncrypted;

    @Column(name = "id_number_hash", nullable = false, unique = true, length = 64)
    private String idNumberHash;

    @Column(name = "id_document_path")
    private String idDocumentPath;

    @Column(name = "residence_document_path", nullable = false)
    private String residenceDocumentPath;

    @Column(name = "residence_document_type")
    private String residenceDocumentType;

    @Column(nullable = false)
    private String status = "PENDING";

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "submitted_at", insertable = false, updatable = false)
    private LocalDateTime submittedAt;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @ManyToOne
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    public HomeownerVerification() {}

    public HomeownerVerification(Homeowner homeowner, byte[] idNumberEncrypted, String idNumberHash,
            String idDocumentPath, String residenceDocumentPath, String residenceDocumentType) {
        this.homeowner = homeowner;
        this.idNumberEncrypted = idNumberEncrypted;
        this.idNumberHash = idNumberHash;
        this.idDocumentPath = idDocumentPath;
        this.residenceDocumentPath = residenceDocumentPath;
        this.residenceDocumentType = residenceDocumentType;
    }

    public Integer getHomeownerId() {
        return homeownerId;
    }

    public void setHomeownerId(Integer homeownerId) {
        this.homeownerId = homeownerId;
    }

    public Homeowner getHomeowner() {
        return homeowner;
    }

    public void setHomeowner(Homeowner homeowner) {
        this.homeowner = homeowner;
    }

    public byte[] getIdNumberEncrypted() {
        return idNumberEncrypted;
    }

    public void setIdNumberEncrypted(byte[] idNumberEncrypted) {
        this.idNumberEncrypted = idNumberEncrypted;
    }

    public String getIdNumberHash() {
        return idNumberHash;
    }

    public void setIdNumberHash(String idNumberHash) {
        this.idNumberHash = idNumberHash;
    }

    public String getIdDocumentPath() {
        return idDocumentPath;
    }

    public void setIdDocumentPath(String idDocumentPath) {
        this.idDocumentPath = idDocumentPath;
    }

    public String getResidenceDocumentPath() {
        return residenceDocumentPath;
    }

    public void setResidenceDocumentPath(String residenceDocumentPath) {
        this.residenceDocumentPath = residenceDocumentPath;
    }

    public String getResidenceDocumentType() {
        return residenceDocumentType;
    }

    public void setResidenceDocumentType(String residenceDocumentType) {
        this.residenceDocumentType = residenceDocumentType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getRejectionReason() {
        return rejectionReason;
    }

    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }

    public LocalDateTime getSubmittedAt() {
        return submittedAt;
    }

    public LocalDateTime getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(LocalDateTime reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public User getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(User reviewedBy) {
        this.reviewedBy = reviewedBy;
    }
}