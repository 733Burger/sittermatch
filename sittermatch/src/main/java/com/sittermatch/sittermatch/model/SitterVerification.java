package com.sittermatch.sittermatch.model;

import jakarta.persistence.*;

@Entity
public class SitterVerification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne
    @JoinColumn(name = "sitter_id", nullable = false)
    private Sitter sitter;

    @Lob
    @Column(columnDefinition = "LONGBLOB")
    private byte[] idPhoto;
    private String idPhotoType;

    @Enumerated(EnumType.STRING)
    private VerificationStatus idStatus = VerificationStatus.INCOMPLETE;
    private String idRejectionReason;

    private String residenceAddress;

    @Enumerated(EnumType.STRING)
    private VerificationStatus residenceStatus = VerificationStatus.INCOMPLETE;
    private String residenceRejectionReason;

    private String emergencyContactName;
    private String emergencyContactPhoneNumber;

    @Enumerated(EnumType.STRING)
    private VerificationStatus emergencyStatus = VerificationStatus.INCOMPLETE;
    private String emergencyRejectionReason;

    @Enumerated(EnumType.STRING)
    private VerificationStatus overallStatus = VerificationStatus.INCOMPLETE;

    public SitterVerification() {}

    public SitterVerification(Sitter sitter) {
        this.sitter = sitter;
    }

    public void refreshOverallStatus() {
        if (idStatus == VerificationStatus.APPROVED && 
            residenceStatus == VerificationStatus.APPROVED && 
            emergencyStatus == VerificationStatus.APPROVED) {
            this.overallStatus = VerificationStatus.APPROVED;
        } else if (idStatus == VerificationStatus.REJECTED || 
                   residenceStatus == VerificationStatus.REJECTED || 
                   emergencyStatus == VerificationStatus.REJECTED) {
            this.overallStatus = VerificationStatus.REJECTED;
        } else if (idStatus == VerificationStatus.PENDING || 
                   residenceStatus == VerificationStatus.PENDING || 
                   emergencyStatus == VerificationStatus.PENDING) {
            this.overallStatus = VerificationStatus.PENDING;
        } else {
            this.overallStatus = VerificationStatus.INCOMPLETE;
        }
    }

    // Getters and Setters
    public Integer getId() { return id; }
    
    public Sitter getSitter() { return sitter; }
    public void setSitter(Sitter sitter) { this.sitter = sitter; }

    public byte[] getIdPhoto() { return idPhoto; }
    public void setIdPhoto(byte[] idPhoto) { this.idPhoto = idPhoto; }
    
    public String getIdPhotoType() { return idPhotoType; }
    public void setIdPhotoType(String idPhotoType) { this.idPhotoType = idPhotoType; }
    
    public VerificationStatus getIdStatus() { return idStatus; }
    public void setIdStatus(VerificationStatus idStatus) { this.idStatus = idStatus; }
    
    public String getIdRejectionReason() { return idRejectionReason; }
    public void setIdRejectionReason(String idRejectionReason) { this.idRejectionReason = idRejectionReason; }

    public String getResidenceAddress() { return residenceAddress; }
    public void setResidenceAddress(String residenceAddress) { this.residenceAddress = residenceAddress; }
    
    public VerificationStatus getResidenceStatus() { return residenceStatus; }
    public void setResidenceStatus(VerificationStatus residenceStatus) { this.residenceStatus = residenceStatus; }
    
    public String getResidenceRejectionReason() { return residenceRejectionReason; }
    public void setResidenceRejectionReason(String residenceRejectionReason) { this.residenceRejectionReason = residenceRejectionReason; }

    public String getEmergencyContactName() { return emergencyContactName; }
    public void setEmergencyContactName(String emergencyContactName) { this.emergencyContactName = emergencyContactName; }
    
    public String getEmergencyContactPhoneNumber() { return emergencyContactPhoneNumber; }
    public void setEmergencyContactPhoneNumber(String emergencyContactPhoneNumber) { this.emergencyContactPhoneNumber = emergencyContactPhoneNumber; }
    
    public VerificationStatus getEmergencyStatus() { return emergencyStatus; }
    public void setEmergencyStatus(VerificationStatus emergencyStatus) { this.emergencyStatus = emergencyStatus; }
    
    public String getEmergencyRejectionReason() { return emergencyRejectionReason; }
    public void setEmergencyRejectionReason(String emergencyRejectionReason) { this.emergencyRejectionReason = emergencyRejectionReason; }

    public VerificationStatus getOverallStatus() { return overallStatus; }
    public void setOverallStatus(VerificationStatus overallStatus) { this.overallStatus = overallStatus; }
}