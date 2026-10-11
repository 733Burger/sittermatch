package com.sittermatch.sittermatch.services;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;

import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.dto.SitterCheckResponse;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.SitterVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.repository.SitterVerificationRepository;

@Service
public class SitterVerificationService {
    private static final long MAX_BYTES = 5L * 1024 * 1024;
    
    private final SitterRepository sitterRepository;
    private final SitterVerificationRepository sitterVerificationRepository;

    public SitterVerificationService(SitterRepository sitterRepository,
                                     SitterVerificationRepository sitterVerificationRepository) {
        this.sitterRepository = sitterRepository;
        this.sitterVerificationRepository = sitterVerificationRepository;
    }

    public IdentityCheckSubmitResponse submitIdentityCheck(String email, MultipartFile idPhoto) {
        if (email == null || email.isBlank()) return IdentityCheckSubmitResponse.failure("Email is required");
        
        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) return IdentityCheckSubmitResponse.failure("Sitter not found");

        if (idPhoto == null || idPhoto.isEmpty() || idPhoto.getSize() > MAX_BYTES) {
            return IdentityCheckSubmitResponse.failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        final byte[] bytes;
        try {
            bytes = idPhoto.getBytes();
        } catch (Exception e) {
            return IdentityCheckSubmitResponse.failure("Could not read the uploaded photo.");
        }

        SitterVerification verification = getOrCreateVerification(sitter.get());
        verification.setIdPhoto(bytes);
        verification.setIdPhotoType("jpg"); 
        verification.setIdStatus(VerificationStatus.PENDING);
        verification.setIdRejectionReason(null);
        saveVerification(verification);

        return new IdentityCheckSubmitResponse(true, "ID Photo uploaded successfully");
    }

    public ResidenceCheckResponse submitResidenceCheck(String email, String address) {
        if (email == null || email.isBlank()) return ResidenceCheckResponse.failure("Email is required");

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) return ResidenceCheckResponse.failure("Sitter not found");

        String cleanAddress = address == null ? "" : address.trim();
        if (cleanAddress.isBlank() || cleanAddress.length() > 255) {
            return ResidenceCheckResponse.failure("Enter an address under 255 characters.");
        }

        SitterVerification verification = getOrCreateVerification(sitter.get());
        verification.setResidenceAddress(cleanAddress);
        verification.setResidenceStatus(VerificationStatus.PENDING);
        verification.setResidenceRejectionReason(null);
        saveVerification(verification);

        return new ResidenceCheckResponse(true, "Address saved");
    }

    public EmergencyCheckResponse submitEmergencyCheck(String email, String name, String phoneNumber) {
        if (email == null || email.isBlank()) return EmergencyCheckResponse.failure("Email is required");

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) return EmergencyCheckResponse.failure("Sitter not found");

        SitterVerification verification = getOrCreateVerification(sitter.get());
        verification.setEmergencyContactName(name.trim());
        verification.setEmergencyContactPhoneNumber(phoneNumber.trim());
        verification.setEmergencyStatus(VerificationStatus.PENDING);
        verification.setEmergencyRejectionReason(null);
        saveVerification(verification);

        return new EmergencyCheckResponse(true, "Emergency contact saved");
    }

    public SitterCheckResponse getVerificationChecks(String email) {
        if (email == null || email.isBlank()) return SitterCheckResponse.failure("Email is required");

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) return SitterCheckResponse.failure("Sitter not found");

        int sitterId = sitter.get().getId();
        Optional<SitterVerification> checks = sitterVerificationRepository.findBySitterId(sitterId);
        
        if (checks.isEmpty()) {
            return SitterCheckResponse.noChecksFound();
        }

        SitterVerification check = checks.get();
        Integer count = sitterVerificationRepository.countVerificationSections(sitterId);
        int verificationCount = (count == null) ? 0 : count;

        return new SitterCheckResponse(
            true,
            SitterCheckResponse.CheckTile.of(check.getIdStatus().name().toLowerCase(), "ID Uploaded"),
            SitterCheckResponse.CheckTile.of(check.getResidenceStatus().name().toLowerCase(), check.getResidenceAddress()),
            SitterCheckResponse.CheckTile.of(check.getEmergencyStatus().name().toLowerCase(), check.getEmergencyContactName()),
            check.getEmergencyContactName(),
            check.getEmergencyContactPhoneNumber(),
            verificationCount,
            check.getOverallStatus().name(),
            "Checks retrieved successfully"
        );
    }

    private SitterVerification getOrCreateVerification(Sitter sitter) {
        return sitterVerificationRepository
                .findBySitterId(sitter.getId())
                .orElseGet(() -> new SitterVerification(sitter));
    }

    private void saveVerification(SitterVerification verification) {
        verification.refreshOverallStatus();
        sitterVerificationRepository.save(verification);
    }
}

       