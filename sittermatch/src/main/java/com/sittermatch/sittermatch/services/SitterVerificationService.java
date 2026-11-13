package com.sittermatch.sittermatch.services;

import java.io.IOException;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.dto.SitterCheckResponse;
import com.sittermatch.sittermatch.dto.SitterCheckResponse.CheckTile;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.SitterVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.repository.SitterVerificationRepository;

import static com.sittermatch.sittermatch.services.VerificationCheckRules.*;

// Mirrors HomeService's verification checks for sitters: same validation, statuses and subtitles.
@Service
public class SitterVerificationService {
    private final SitterRepository sitterRepository;
    private final SitterVerificationRepository sitterVerificationRepository;

    public SitterVerificationService(SitterRepository sitterRepository,
                                     SitterVerificationRepository sitterVerificationRepository) {
        this.sitterRepository = sitterRepository;
        this.sitterVerificationRepository = sitterVerificationRepository;
    }

    public IdentityCheckSubmitResponse submitIdentityCheck(String email, MultipartFile idPhoto) {
        if (email == null || email.isBlank()) {
            return IdentityCheckSubmitResponse.failure("Email is required");
        }

        if (idPhoto == null || idPhoto.isEmpty() || idPhoto.getSize() > MAX_ID_PHOTO_BYTES) {
            return IdentityCheckSubmitResponse.failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) {
            return IdentityCheckSubmitResponse.failure("Sitter not found");
        }

        final byte[] bytes;
        try {
            bytes = idPhoto.getBytes();
        } catch (IOException e) {
            return IdentityCheckSubmitResponse.failure("Could not read the uploaded photo.");
        }

        if (bytes.length == 0 || bytes.length > MAX_ID_PHOTO_BYTES) {
            return IdentityCheckSubmitResponse.failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        String extension = idPhotoExtension(bytes);
        if (extension == null) {
            return IdentityCheckSubmitResponse.failure("ID photo must be a JPG, PNG, or WEBP.");
        }

        SitterVerification verification = getOrCreateVerification(sitter.get());
        verification.setIdPhoto(bytes);
        verification.setIdPhotoType(extension);
        verification.setIdStatus(VerificationStatus.PENDING);
        verification.setIdRejectionReason(null);
        saveVerification(verification);

        return new IdentityCheckSubmitResponse(true, "ID Photo uploaded successfully");
    }

    public ResidenceCheckResponse submitResidenceCheck(String email, String address) {
        if (email == null || email.isBlank()) {
            return ResidenceCheckResponse.failure("Email is required");
        }

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) {
            return ResidenceCheckResponse.failure("Sitter not found");
        }

        String cleanAddress = address == null ? "" : address.trim();
        if (cleanAddress.isBlank() || cleanAddress.length() > 255) {
            return ResidenceCheckResponse.failure("Enter a home address under 255 characters.");
        }

        SitterVerification verification = getOrCreateVerification(sitter.get());
        verification.setResidenceAddress(cleanAddress);
        verification.setResidenceStatus(VerificationStatus.PENDING);
        verification.setResidenceRejectionReason(null);
        saveVerification(verification);

        return new ResidenceCheckResponse(true, "Home address saved");
    }

    public EmergencyCheckResponse submitEmergencyCheck(String email, String name, String phoneNumber) {
        if (email == null || email.isBlank()) {
            return EmergencyCheckResponse.failure("Email is required");
        }

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) {
            return EmergencyCheckResponse.failure("Sitter not found");
        }

        String cleanName = name == null ? "" : name.trim();
        if (!isValidEmergencyName(cleanName)) {
            return EmergencyCheckResponse.failure("Enter an emergency contact name under 100 characters.");
        }

        String cleanPhone = phoneNumber == null ? "" : phoneNumber.trim();
        if (!isValidEmergencyPhone(cleanPhone)) {
            return EmergencyCheckResponse.failure("Enter a phone number under 20 characters.");
        }

        SitterVerification verification = getOrCreateVerification(sitter.get());
        verification.setEmergencyContactName(cleanName);
        verification.setEmergencyContactPhoneNumber(cleanPhone);
        verification.setEmergencyStatus(VerificationStatus.PENDING);
        verification.setEmergencyRejectionReason(null);
        saveVerification(verification);

        return new EmergencyCheckResponse(true, "Emergency contact saved");
    }

    public SitterCheckResponse getVerificationChecks(String email) {
        if (email == null || email.isBlank()) {
            return SitterCheckResponse.failure("Email is required");
        }

        Optional<Sitter> sitter = sitterRepository.findByUserEmail(email.trim());
        if (sitter.isEmpty()) {
            return SitterCheckResponse.failure("Sitter not found");
        }

        int sitterId = sitter.get().getId();
        Optional<SitterVerification> checks = sitterVerificationRepository.findBySitterId(sitterId);
        if (checks.isEmpty()) {
            return SitterCheckResponse.noChecksFound();
        }

        SitterVerification check = checks.get();
        Integer count = sitterVerificationRepository.countVerificationSections(sitterId);
        int verificationCount = (count == null) ? 0 : count;

        String name = emptyIfNull(check.getEmergencyContactName());
        String phone = emptyIfNull(check.getEmergencyContactPhoneNumber());
        VerificationStatus overall = check.getOverallStatus() == null
                ? VerificationStatus.INCOMPLETE
                : check.getOverallStatus();

        return new SitterCheckResponse(
            true,
            CheckTile.of(tileStatus(check.getIdStatus()), idSubtitle(check.getIdStatus())),
            CheckTile.of(tileStatus(check.getResidenceStatus()), residenceSubtitle(check.getResidenceAddress())),
            CheckTile.of(tileStatus(check.getEmergencyStatus()), emergencySubtitle(name, phone)),
            name,
            phone,
            verificationCount,
            overall.name(),
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
