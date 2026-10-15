package com.sittermatch.sittermatch.services;

import java.io.IOException;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.dto.UpdateProfileRequest;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.HomeownerCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.HomeownerCheckResponse.CheckTile;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.HomeownerVerificationRepository;
import com.sittermatch.sittermatch.dto.ProfileResponse;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repository.UserRepository;
import org.springframework.transaction.annotation.Transactional;



@Service
public class HomeService {
    private static final long MAX_BYTES = 5L * 1024 * 1024;
    private final HomeownerRepository homeownerRepository;
    private final HomeownerVerificationRepository homeownerVerificationRepository;
    private final UserRepository userRepository;

    public HomeService(HomeownerRepository homeownerRepository,
            HomeownerVerificationRepository homeownerVerificationRepository, UserRepository userRepository) {
        this.homeownerRepository = homeownerRepository;
        this.homeownerVerificationRepository = homeownerVerificationRepository;
        this.userRepository = userRepository;
    }

    public ProfileResponse getProfile(Integer userId) {
        Optional<Homeowner> found = homeownerRepository.findById(userId);
        if (found.isEmpty()) {
            return ProfileResponse.failure("Homeowner not found");
        }
        return toProfileResponse(found.get(), "Profile loaded");
    }

    @Transactional
    public ProfileResponse updateProfile(Integer userId, UpdateProfileRequest req) {
        Optional<Homeowner> found = homeownerRepository.findById(userId);
        if (found.isEmpty()) {
            return ProfileResponse.failure("Homeowner not found");
        }

        String name = req.name() == null ? "" : req.name().trim();
        String email = req.email() == null ? "" : req.email().trim().toLowerCase();
        String phone = req.phone() == null ? "" : req.phone().trim();
        String address = req.address() == null ? "" : req.address().trim();
        String requirements = req.requirements() == null ? "" : req.requirements().trim();

        if (name.isBlank() || name.length() > 100) {
            return ProfileResponse.failure("Enter a name under 100 characters.");
        }
        if (email.isBlank() || email.length() > 255 || !email.contains("@")) {
            return ProfileResponse.failure("Enter a valid email address.");
        }
        if (phone.length() > 20 || (!phone.isEmpty() && !phone.matches("[0-9+()\\- ]+"))) {
            return ProfileResponse.failure("Enter a phone number under 20 characters.");
        }
        if (address.isBlank() || address.length() > 255) {
            return ProfileResponse.failure("Enter an address under 255 characters.");
        }
        if (requirements.isBlank() || requirements.length() > 255) {
            return ProfileResponse.failure("Requirements must be 1-255 characters.");
        }

        Optional<User> emailOwner = userRepository.findByEmailIgnoreCase(email);
        if (emailOwner.isPresent() && !emailOwner.get().getId().equals(userId)) {
            return ProfileResponse.failure("That email is already in use.");
        }

        Homeowner homeowner = found.get();
        User user = homeowner.getUser();
        user.setName(name);
        user.setEmail(email);
        user.setPhone(phone);
        homeowner.setAddress(address);
        homeowner.setRequirements(requirements);

        userRepository.save(user);
        homeownerRepository.save(homeowner);

        return toProfileResponse(homeowner, "Profile updated");
    }

    private ProfileResponse toProfileResponse(Homeowner h, String message) {
        User u = h.getUser();
        return new ProfileResponse(true, message, u.getName(), u.getEmail(), u.getPhone(),
                emptyIfNull(h.getAddress()), emptyIfNull(h.getRequirements()));
    }

    public IdentityCheckSubmitResponse submitIdentityCheck(String email, MultipartFile idPhoto) {
        if (email == null || email.isBlank()) {
            return IdentityCheckSubmitResponse.failure("Email is required");
        }
        String cleanEmail = email.trim();

        if (idPhoto == null || idPhoto.isEmpty() || idPhoto.getSize() > MAX_BYTES) {
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
        
        if (bytes.length == 0 || bytes.length > MAX_BYTES) {
            return IdentityCheckSubmitResponse.failure("ID photo must be a JPG, PNG, or WEBP under 5 MB.");
        }

        String extension = extensionFor(bytes);
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
        if (cleanName.isBlank() || cleanName.length() > 100) {
            return EmergencyCheckResponse.failure("Enter an emergency contact name under 100 characters.");
        }

        String cleanPhone = phoneNumber == null ? "" : phoneNumber.trim();
        if (cleanPhone.isBlank() || cleanPhone.length() > 20 || !cleanPhone.matches("[0-9+()\\- ]+")) {
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
                CheckTile.of(tileStatus(check.getIdStatus()), getIdSubtitle(check)),
                CheckTile.of(tileStatus(check.getResidenceStatus()), getResidenceSubtitle(check)),
                CheckTile.of(tileStatus(check.getEmergencyStatus()), getEmergencySubtitle(name, phone)),
                name,
                phone,
                verificationCount,
                check.getOverallStatus().name()
            );
        }
    }
    //helper class for getVerificationChecks
    private static String emptyIfNull(String string) {
        return (string == null) ? "" : string;
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
    //helper class for getVerificationChecks
    private String getIdSubtitle(HomeownerVerification check) {
        return switch (check.getIdStatus()) {
            case PENDING -> "ID uploaded";
            case APPROVED -> "ID verified";
            case REJECTED -> "ID rejected";
            case INCOMPLETE -> "No ID uploaded";
        };
    }
    //helper class for getVerificationChecks
    private String getResidenceSubtitle(HomeownerVerification check) {
        String address = check.getResidenceAddress();
        return (address == null || address.isBlank()) ? "No address provided" : address;
    }
    //helper class for getVerificationChecks
    private String getEmergencySubtitle(String name, String phone) {
        if (name.isBlank() && phone.isBlank()) {
            return "No Emergency Contact Uploaded";
        }

        if (name.isBlank()) {
            return "No contact name - " + phone;
        }

        if (phone.isBlank()) {
            return name + " - No contact details provided";
        }

        return name + " - " + phone;
    }
}