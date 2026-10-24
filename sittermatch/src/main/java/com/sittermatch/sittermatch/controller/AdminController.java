package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.admin.AdminReviewDto;
import com.sittermatch.sittermatch.dto.admin.AdminUserCheckDto;
import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.SitterVerification;
import com.sittermatch.sittermatch.model.VerificationStatus;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.HomeownerVerificationRepository;
import com.sittermatch.sittermatch.repository.SitterVerificationRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.repository.UserRepository;
import com.sittermatch.sittermatch.services.ReviewService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private HomeownerVerificationRepository homeownerVerificationRepository;
    @Autowired
    private SitterVerificationRepository sitterVerificationRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private SitterRepository sitterRepository;
    @Autowired private HomeownerRepository homeownerRepository;
    @Autowired private ReviewService reviewService;

   @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
       List<AdminUserCheckDto> pending = getPendingChecks().getBody();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", userRepository.countByActiveRoleNot("ADMIN"));
        stats.put("sitters", sitterRepository.count());
        stats.put("homeowners", homeownerRepository.count());
        stats.put("pendingChecks", pending == null ? 0 : pending.size());
        stats.put("pendingReviews", reviewService.getPendingReviews().size());
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/pending-checks")
    public ResponseEntity<List<AdminUserCheckDto>> getPendingChecks() {
        List<AdminUserCheckDto> pendingList = new ArrayList<>();

        // 1. Fetch pending homeowner verifications using your existing repository method
        List<HomeownerVerification> homeownerVerifs = homeownerVerificationRepository.findAwaitingReview(VerificationStatus.PENDING);
        for (HomeownerVerification v : homeownerVerifs) {
            String userName = (v.getHomeowner() != null && v.getHomeowner().getUser() != null)
                ? v.getHomeowner().getUser().getName()
                : "Unknown Homeowner";

            if (v.getIdStatus() == VerificationStatus.PENDING) {
                pendingList.add(new AdminUserCheckDto(
                   (long) v.getHomeownerId() * 10 + 1,
                    userName,
                    "HOMEOWNER",
                    "Identity / SA ID",
                    "ID photo uploaded",
                    "Recently"
                ));
            }
            if (v.getResidenceStatus() == VerificationStatus.PENDING) {
                pendingList.add(new AdminUserCheckDto(
                    (long) v.getHomeownerId() * 10 + 2,
                    userName,
                    "HOMEOWNER",
                    "Home Address / Proof of Residence",
                    v.getResidenceAddress() != null ? v.getResidenceAddress() : "Address provided",
                    "Recently"
                ));
            }
            if (v.getEmergencyStatus() == VerificationStatus.PENDING) {
                pendingList.add(new AdminUserCheckDto(
                    (long) v.getHomeownerId() * 10 + 3,
                    userName,
                    "HOMEOWNER",
                    "Emergency Contact Details",
                    v.getEmergencyContactName() + " (" + v.getEmergencyContactPhoneNumber() + ")",
                    "Recently"
                ));
            }
        }

                // 2. Sitter checks. Sitter check ids are sitterId * 10 + 4 (ID), 5 (address), 6 (emergency contact)
        List<SitterVerification> sitterVerifs = sitterVerificationRepository.findAwaitingReview(VerificationStatus.PENDING);
        for (SitterVerification v : sitterVerifs) {
            if (v.getSitter() == null) continue;

            long sitterId = v.getSitter().getId();
            String userName = v.getSitter().getUser() != null
                ? v.getSitter().getUser().getName()
                : "Unknown Sitter";

            if (v.getIdStatus() == VerificationStatus.PENDING) {
                pendingList.add(new AdminUserCheckDto(
                    sitterId * 10 + 4,
                    userName,
                    "SITTER",
                    "Identity / SA ID",
                    "ID photo uploaded",
                    "Recently"
                ));
            }
            if (v.getResidenceStatus() == VerificationStatus.PENDING) {
                pendingList.add(new AdminUserCheckDto(
                    sitterId * 10 + 5,
                    userName,
                    "SITTER",
                    "Home Address / Proof of Residence",
                    v.getResidenceAddress() != null ? v.getResidenceAddress() : "Address provided",
                    "Recently"
                ));
            }
            if (v.getEmergencyStatus() == VerificationStatus.PENDING) {
                pendingList.add(new AdminUserCheckDto(
                    sitterId * 10 + 6,
                    userName,
                    "SITTER",
                    "Emergency Contact Details",
                    v.getEmergencyContactName() + " (" + v.getEmergencyContactPhoneNumber() + ")",
                    "Recently"
                ));
            }
        }
        return ResponseEntity.ok(pendingList);
    }

    @Transactional 
    @PostMapping("/resolve-check")
    public ResponseEntity<Map<String, Object>> resolveCheck(@RequestBody Map<String, Object> request) {
        Long compositeId = Long.valueOf(request.get("checkId").toString());
        boolean approved = (Boolean) request.get("approved");
        String reason = (String) request.get("reason");

        long entityId = compositeId / 10;
        int checkTypeDiscriminator = (int) (compositeId % 10);
        VerificationStatus targetStatus = approved ? VerificationStatus.APPROVED : VerificationStatus.REJECTED;

        // Check if it's a Homeowner verification (discriminator 1, 2, 3)
        if (checkTypeDiscriminator >= 1 && checkTypeDiscriminator <= 3) {
            Optional<HomeownerVerification> optVerification = homeownerVerificationRepository.findById((int) entityId);
            if (optVerification.isPresent()) {
                HomeownerVerification v = optVerification.get();
                if (checkTypeDiscriminator == 1) {
                    v.setIdStatus(targetStatus);
                    if (!approved) v.setIdRejectionReason(reason);
                } else if (checkTypeDiscriminator == 2) {
                    v.setResidenceStatus(targetStatus);
                    if (!approved) v.setResidenceRejectionReason(reason);
                } else if (checkTypeDiscriminator == 3) {
                    v.setEmergencyStatus(targetStatus);
                    if (!approved) v.setEmergencyRejectionReason(reason);
                }

                v.refreshOverallStatus();
                v.setReviewedAt(LocalDateTime.now());
                homeownerVerificationRepository.save(v);

                return ResponseEntity.ok(Map.of("success", true, "message", "Check updated successfully"));
            }
        } 
        // Check if it's a Sitter verification (discriminator 4, 5, 6)
        else if (checkTypeDiscriminator >= 4 && checkTypeDiscriminator <= 6) {
            Optional<SitterVerification> optVerification = sitterVerificationRepository.findById((int) entityId);
            if (optVerification.isPresent()) {
                SitterVerification v = optVerification.get();
                if (checkTypeDiscriminator == 4) {
                    v.setIdStatus(targetStatus);
                    if (!approved) v.setIdRejectionReason(reason);
                } else if (checkTypeDiscriminator == 5) {
                    v.setResidenceStatus(targetStatus);
                    if (!approved) v.setResidenceRejectionReason(reason);
                } else if (checkTypeDiscriminator == 6) {
                    v.setEmergencyStatus(targetStatus);
                    if (!approved) v.setEmergencyRejectionReason(reason);
                }

                v.refreshOverallStatus();
                v.setReviewedAt(LocalDateTime.now());
                sitterVerificationRepository.save(v);

                return ResponseEntity.ok(Map.of("success", true, "message", "Check updated successfully"));
            }
        }

        return ResponseEntity.status(404).body(Map.of("success", false, "message", "Verification record not found"));
    }

    /** Reviews waiting for approval. They don't show on profiles or count towards ratings yet. */
    @GetMapping("/pending-reviews")
    public ResponseEntity<List<AdminReviewDto>> getPendingReviews() {
        return ResponseEntity.ok(reviewService.getPendingReviews());
    }

    /** approved = true publishes the review; false removes it. */
    @PostMapping("/resolve-review")
    public ResponseEntity<Map<String, Object>> resolveReview(@RequestBody Map<String, Object> request) {
        try {
            Integer reviewId = Integer.valueOf(request.get("reviewId").toString());
            boolean approved = Boolean.TRUE.equals(request.get("approved"));
            reviewService.resolveReview(reviewId, approved);
            return ResponseEntity.ok(Map.of("success", true,
                    "message", approved ? "Review published" : "Review removed"));
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message",
                    e.getMessage() == null ? "reviewId is required" : e.getMessage()));
        }
    }
}