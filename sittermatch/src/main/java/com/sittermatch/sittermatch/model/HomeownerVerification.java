package com.sittermatch.sittermatch.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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

    //SA ID(photo)
    @Lob
    @JdbcTypeCode(SqlTypes.BLOB)
    @Column(name = "id_photo", columnDefinition = "MEDIUMBLOB")
    private byte[] idPhoto;

    @Column(name = "id_photo_type", length = 10)
    private String idPhotoType;

    @Enumerated(EnumType.STRING)
    @Column(name = "id_status", nullable = false)
    private VerificationStatus idStatus = VerificationStatus.INCOMPLETE;

    @Column(name = "id_rejection_reason", length = 255)
    private String idRejectionReason;

    // Proof of residence
    @Column(name = "residence_address", length = 255)
    private String residenceAddress;

    @Enumerated(EnumType.STRING)
    @Column(name = "residence_status", nullable = false)
    private VerificationStatus residenceStatus = VerificationStatus.INCOMPLETE;

    @Column(name = "residence_rejection_reason", length = 255)
    private String residenceRejectionReason;

    // Emergency contact
    @Column(name = "emergency_contact_name", length = 100)
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone_number", length = 20)
    private String emergencyContactPhoneNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "emergency_status", nullable = false)
    private VerificationStatus emergencyStatus = VerificationStatus.INCOMPLETE;

    @Column(name = "emergency_rejection_reason", length = 255)
    private String emergencyRejectionReason;

    @Enumerated(EnumType.STRING)
    @Column(name = "overall_status", nullable = false)
    private VerificationStatus overallStatus = VerificationStatus.INCOMPLETE;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @ManyToOne
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private LocalDateTime updatedAt;

    public HomeownerVerification() {}

    public HomeownerVerification(Homeowner homeowner) {
        this.homeowner = homeowner;
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

    public byte[] getIdPhoto() {
        return idPhoto;
    }

    public void setIdPhoto(byte[] idPhoto) {
        this.idPhoto = idPhoto;
    }

    public String getIdPhotoType() {
        return idPhotoType;
    }

    public void setIdPhotoType(String idPhotoType) {
        this.idPhotoType = idPhotoType;
    }

    public VerificationStatus getIdStatus() {
        return idStatus;
    }

    public void setIdStatus(VerificationStatus idStatus) {
        this.idStatus = idStatus;
    }

    public String getIdRejectionReason() {
        return idRejectionReason;
    }
    
    public void setIdRejectionReason(String idRejectionReason) {
        this.idRejectionReason = idRejectionReason;
    }

    public String getResidenceAddress() {
        return residenceAddress;
    }

    public void setResidenceAddress(String residenceAddress) {
        this.residenceAddress = residenceAddress;
    }

    public VerificationStatus getResidenceStatus() {
        return residenceStatus;
    }

    public void setResidenceStatus(VerificationStatus residenceStatus) {
        this.residenceStatus = residenceStatus;
    }

    public String getResidenceRejectionReason() {
        return residenceRejectionReason;
    }

    public void setResidenceRejectionReason(String residenceRejectionReason) {
        this.residenceRejectionReason = residenceRejectionReason;
    }

    public String getEmergencyContactName() {
        return emergencyContactName;
    }

    public void setEmergencyContactName(String emergencyContactName) {
        this.emergencyContactName = emergencyContactName;
    }

    public String getEmergencyContactPhoneNumber() {
        return emergencyContactPhoneNumber;
    }

    public void setEmergencyContactPhoneNumber(String emergencyContactPhoneNumber) {
        this.emergencyContactPhoneNumber = emergencyContactPhoneNumber;
    }

    public VerificationStatus getEmergencyStatus() {
        return emergencyStatus;
    }

    public void setEmergencyStatus(VerificationStatus emergencyStatus) {
        this.emergencyStatus = emergencyStatus;
    }

    public String getEmergencyRejectionReason() {
        return emergencyRejectionReason;
    }

    public void setEmergencyRejectionReason(String emergencyRejectionReason) {
        this.emergencyRejectionReason = emergencyRejectionReason;
    }

    public VerificationStatus getOverallStatus() {
        return overallStatus;
    }

    public void setOverallStatus(VerificationStatus overallStatus) {
        this.overallStatus = overallStatus;
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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void refreshOverallStatus() {
        if (isRejected()) {
            overallStatus = VerificationStatus.REJECTED;
        } else if (isApproved()) {
            overallStatus = VerificationStatus.APPROVED;
        } else if (isSubmitted()) {
            overallStatus = VerificationStatus.PENDING;
        } else {
            overallStatus = VerificationStatus.INCOMPLETE;
        }
    }

    public boolean isApproved() {
        return idStatus == VerificationStatus.APPROVED
            && residenceStatus == VerificationStatus.APPROVED
            && emergencyStatus == VerificationStatus.APPROVED;
    }

    public boolean isRejected() {
        return idStatus == VerificationStatus.REJECTED 
            || residenceStatus == VerificationStatus.REJECTED 
            || emergencyStatus == VerificationStatus.REJECTED;
    }

    private boolean isSubmitted() {
        return hasBeenSubmitted(idStatus)
            && hasBeenSubmitted(residenceStatus)
            && hasBeenSubmitted(emergencyStatus);
    }

    private boolean hasBeenSubmitted(VerificationStatus status) {
        return status == VerificationStatus.PENDING
            || status == VerificationStatus.APPROVED;
    }
}