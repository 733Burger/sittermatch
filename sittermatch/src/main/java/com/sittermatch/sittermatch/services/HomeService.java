package com.sittermatch.sittermatch.services;

import java.io.IOException;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.HomeownerCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.HomeownerCheckResponse.CheckTile;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.HomeownerVerificationRepository;

import static com.sittermatch.sittermatch.services.VerificationCheckRules.*;

@Service
public class HomeService {
    private final HomeownerRepository homeownerRepository;
    private final HomeownerVerificationRepository homeownerVerificationRepository;

    public HomeService(HomeownerRepository homeownerRepository,
                    HomeownerVerificationRepository homeownerVerificationRepository) {
        this.homeownerRepository = homeownerRepository;
        this.homeownerVerificationRepository = homeownerVerificationRepository;
    }

    public IdentityCheckSubmitResponse submitIdentityCheck(String email, MultipartFile idPhoto) {
        if (email == null || email.isBlank()) {
            return IdentityCheckSubmitResponse.failure("Email is required");
        }
        String cleanEmail = email.trim();

        if (idPhoto == null || idPhoto.isEmpty() || idPhoto.getSize() > MAX_ID_PHOTO_BYTES) {
            return IdentityCheckSubmitResponse.failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(cleanEmail);
        if (homeowner.isEmpty()) {
            return IdentityCheckSubmitResponse.failure("Homeowner not found");
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

        HomeownerVerification verification = getOrCreateVerification(homeowner.get());
        verification.setIdPhoto(bytes);
        verification.setIdPhotoType(extension);
        verification.setIdStatus(VerificationStatus.PENDING);
        verification.setIdRejectionReason(null);
        saveVerification(verification);

        return new IdentityCheckSubmitResponse(
                true,
                "ID Photo uploaded successfully");
    }

    public ResidenceCheckResponse submitResidenceCheck(String email, String address) {
        if (email == null || email.isBlank()) {
            return ResidenceCheckResponse.failure("Email is required");
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(email.trim());
        if (homeowner.isEmpty()) {
            return ResidenceCheckResponse.failure("Homeowner not found");
        }

        String cleanAddress = address == null ? "" : address.trim();
        if (cleanAddress.isBlank() || cleanAddress.length() > 255) {
            return ResidenceCheckResponse.failure("Enter a home address under 255 characters.");
        }

        HomeownerVerification verification = getOrCreateVerification(homeowner.get());
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

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(email.trim());
        if (homeowner.isEmpty()) {
            return EmergencyCheckResponse.failure("Homeowner not found");
        }

        String cleanName = name == null ? "" : name.trim();
        if (!isValidEmergencyName(cleanName)) {
            return EmergencyCheckResponse.failure("Enter an emergency contact name under 100 characters.");
        }

        String cleanPhone = phoneNumber == null ? "" : phoneNumber.trim();
        if (!isValidEmergencyPhone(cleanPhone)) {
            return EmergencyCheckResponse.failure("Enter a phone number under 20 characters.");
        }

        HomeownerVerification verification = getOrCreateVerification(homeowner.get());
        verification.setEmergencyContactName(cleanName);
        verification.setEmergencyContactPhoneNumber(cleanPhone);
        verification.setEmergencyStatus(VerificationStatus.PENDING);
        verification.setEmergencyRejectionReason(null);
        saveVerification(verification);

        return new EmergencyCheckResponse(true, "Emergency contact saved");
    }

    private HomeownerVerification getOrCreateVerification(Homeowner owner) {
        return homeownerVerificationRepository
                .findByHomeownerId(owner.getId())
                .orElseGet(() -> new HomeownerVerification(owner));
    }

    private void saveVerification(HomeownerVerification verification) {
        verification.refreshOverallStatus();
        homeownerVerificationRepository.save(verification);
    }

    public HomeownerCheckResponse getVerificationChecks(int homeownerId) {
        if (homeownerId <= 0) {
            return HomeownerCheckResponse.failure("Homeowner not found");
        }

        Optional<HomeownerVerification> checks = homeownerVerificationRepository.findByHomeownerId(homeownerId);
        if (checks.isEmpty()) {
            return HomeownerCheckResponse.noChecksFound();
        } else {
            HomeownerVerification check = checks.get();

            Integer count = homeownerVerificationRepository.countVerificationSections(homeownerId);
            int verificationCount = (count == null) ? 0 : count;

            String name = emptyIfNull(check.getEmergencyContactName());
            String phone = emptyIfNull(check.getEmergencyContactPhoneNumber());

            return new HomeownerCheckResponse(
                true,
                CheckTile.of(tileStatus(check.getIdStatus()), idSubtitle(check.getIdStatus())),
                CheckTile.of(tileStatus(check.getResidenceStatus()), residenceSubtitle(check.getResidenceAddress())),
                CheckTile.of(tileStatus(check.getEmergencyStatus()), emergencySubtitle(name, phone)),
                name,
                phone,
                verificationCount,
                check.getOverallStatus().name()
            );
        }
    }
}
