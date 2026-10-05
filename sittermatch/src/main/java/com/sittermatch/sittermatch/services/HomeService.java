package com.sittermatch.sittermatch.services;

import java.io.IOException;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.sittermatch.sittermatch.dto.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.HomeownerCheckResponse;
import com.sittermatch.sittermatch.dto.HomeownerCheckResponse.CheckTile;
import com.sittermatch.sittermatch.dto.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.HomeownerVerificationRepository;

@Service
public class HomeService {
    private static final long MAX_BYTES = 5L * 1024 * 1024;

    private final HomeownerRepository homeownerRepository;
    private final HomeownerVerificationRepository homeownerVerificationRepository;

    public HomeService(HomeownerRepository homeownerRepository,
                       HomeownerVerificationRepository homeownerVerificationRepository) {
        this.homeownerRepository = homeownerRepository;
        this.homeownerVerificationRepository = homeownerVerificationRepository;
    }

    private IdentityCheckSubmitResponse failure(String message) {
        return new IdentityCheckSubmitResponse(false, message, null);
    }

    private HomeownerVerification verificationFor(Homeowner owner) {
        return homeownerVerificationRepository
                .findByHomeownerId(owner.getId())
                .orElseGet(() -> new HomeownerVerification(owner));
    }

    public IdentityCheckSubmitResponse submitIdentityCheck(String email, MultipartFile idPhoto) {
        if (email == null || email.isBlank()) {
            return failure("Email is required");
        }
        String cleanEmail = email.trim();

        if (idPhoto == null || idPhoto.isEmpty() || idPhoto.getSize() > MAX_BYTES) {
            return failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(cleanEmail);
        if (homeowner.isEmpty()) {
            return failure("Homeowner not found");
        }

        final byte[] bytes;
        try {
            bytes = idPhoto.getBytes();
        } catch (IOException e) {
            return failure("Could not read the uploaded photo.");
        }
        if (bytes.length == 0 || bytes.length > MAX_BYTES) {
            return failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        String extension = extensionFor(bytes);
        if (extension == null) {
            return failure("ID photo must be a JPG, PNG, or WEBP.");
        }

        HomeownerVerification verification = verificationFor(homeowner.get());
        verification.setIdPhoto(bytes);
        verification.setIdPhotoType(extension);
        verification.setIdStatus(VerificationStatus.PENDING);
        verification.setIdRejectionReason(null);
        homeownerVerificationRepository.save(verification);

        return new IdentityCheckSubmitResponse(
                true,
                "ID Photo uploaded successfully",
                new IdentityCheckSubmitResponse.IdCheck("pending"));
    }

    public ResidenceCheckResponse submitResidence(String email, String address) {
        if (email == null || email.isBlank()) {
            return new ResidenceCheckResponse(false, "Email is required");
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(email.trim());
        if (homeowner.isEmpty()) {
            return new ResidenceCheckResponse(false, "Homeowner not found");
        }

        String cleanAddress = address == null ? "" : address.trim();
        if (cleanAddress.isBlank() || cleanAddress.length() > 255) {
            return new ResidenceCheckResponse(false, "Enter a home address under 255 characters.");
        }

        HomeownerVerification verification = verificationFor(homeowner.get());
        verification.setResidenceAddress(cleanAddress);
        verification.setResidenceStatus(VerificationStatus.PENDING);
        verification.setResidenceRejectionReason(null);
        homeownerVerificationRepository.save(verification);

        return new ResidenceCheckResponse(
                true,
                "Home address saved");
    }

    public EmergencyCheckResponse submitEmergency(String email, String name, String phoneNumber) {
        if (email == null || email.isBlank()) {
            return new EmergencyCheckResponse(false, "Email is required");
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(email.trim());
        if (homeowner.isEmpty()) {
            return new EmergencyCheckResponse(false, "Homeowner not found");
        }

        String cleanName = name == null ? "" : name.trim();
        String cleanPhone = phoneNumber == null ? "" : phoneNumber.trim();
        if (cleanName.isBlank() || cleanName.length() > 100) {
            return new EmergencyCheckResponse(false, "Enter an emergency contact name under 100 characters.");
        }
        if (cleanPhone.isBlank() || cleanPhone.length() > 20 || !cleanPhone.matches("[0-9+()\\- ]+")) {
            return new EmergencyCheckResponse(false, "Enter a phone number under 20 characters.");
        }

        HomeownerVerification verification = verificationFor(homeowner.get());
        verification.setEmergencyContactName(cleanName);
        verification.setEmergencyContactPhoneNumber(cleanPhone);
        verification.setEmergencyStatus(VerificationStatus.PENDING);
        verification.setEmergencyRejectionReason(null);
        homeownerVerificationRepository.save(verification);

        return new EmergencyCheckResponse(
                true,
                "Emergency contact saved");
    }

    private String extensionFor(byte[] bytes) {
        if (bytes.length >= 3
                && (bytes[0] & 0xFF) == 0xFF
                && (bytes[1] & 0xFF) == 0xD8
                && (bytes[2] & 0xFF) == 0xFF) {
            return "jpg";
        }
        if (bytes.length >= 8
                && (bytes[0] & 0xFF) == 0x89
                && bytes[1] == 0x50
                && bytes[2] == 0x4E
                && bytes[3] == 0x47
                && bytes[4] == 0x0D
                && bytes[5] == 0x0A
                && bytes[6] == 0x1A
                && bytes[7] == 0x0A) {
            return "png";
        }
        if (bytes.length >= 12
                && bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F'
                && bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P') {
            return "webp";
        }
        return null;
    }

    public HomeownerCheckResponse getVerificationChecks(String email) {
        if (email == null || email.isBlank()) {
            return HomeownerCheckResponse.failure("Email is required");
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(email.trim());
        if (homeowner.isEmpty()) {
            return HomeownerCheckResponse.failure("Homeowner not found");
        }

        int homeownerId = homeowner.get().getId();
        Optional<HomeownerVerification> checks = homeownerVerificationRepository.findByHomeownerId(homeownerId);
        if (checks.isEmpty()) {
            return HomeownerCheckResponse.noChecksFound();
        } else {
            HomeownerVerification check = checks.get();
            return new HomeownerCheckResponse(
                true,
                "Checks retrieved successfully",
                CheckTile.of(tileStatus(check.getIdStatus()), getIdStatus(check)),
                CheckTile.of(tileStatus(check.getResidenceStatus()), check.getResidenceAddress()),
                CheckTile.of(tileStatus(check.getEmergencyStatus()), check.getEmergencyContactName() + " - " + check.getEmergencyContactPhoneNumber()),
                check.getEmergencyContactName(),
                check.getEmergencyContactPhoneNumber()
            );
        }
    }
    //helper class for getVerificationChecks
    private String getIdStatus(HomeownerVerification check) {
        return switch (check.getIdStatus()) {
            case PENDING -> "ID uploaded";
            case APPROVED -> "ID verified";
            case REJECTED -> "ID rejected";
            case INCOMPLETE -> "No ID uploaded";
        };
    }
    //helper class for getVerificationChecks
    private String tileStatus(VerificationStatus status) {
        return switch (status) {
            case PENDING -> "pending";
            case APPROVED -> "completed";
            case REJECTED -> "rejected";
            case INCOMPLETE -> "incomplete";
        };
    }
}