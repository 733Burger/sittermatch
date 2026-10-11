package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.ResidenceCheckRequest;
import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckRequest;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.dto.SitterCheckResponse;
import com.sittermatch.sittermatch.services.SitterVerificationService;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/sitter-verifications")
@CrossOrigin(origins = "*") 
public class SitterVerificationController {

    private final SitterVerificationService sitterVerificationService;

    public SitterVerificationController(SitterVerificationService sitterVerificationService) {
        this.sitterVerificationService = sitterVerificationService;
    }

    @GetMapping("/{email:.+}/get-checks")
    public ResponseEntity<SitterCheckResponse> getChecks(@PathVariable String email) {
        SitterCheckResponse verificationCheck = sitterVerificationService.getVerificationChecks(email);
        if (!verificationCheck.success()) {
            return ResponseEntity.badRequest().body(verificationCheck);
        }
        return ResponseEntity.ok(verificationCheck);
    }

    @PostMapping(value = "/identity-check", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<IdentityCheckSubmitResponse> submitIdentityCheck(
            @RequestParam("email") String email,
            @RequestParam("idPhoto") MultipartFile idPhoto) {
        IdentityCheckSubmitResponse identityCheck = sitterVerificationService.submitIdentityCheck(email, idPhoto);
        if (!identityCheck.success()) {
            return ResponseEntity.badRequest().body(identityCheck);
        }
        return ResponseEntity.ok(identityCheck);
    }

    @PostMapping("/residence-check")
    public ResponseEntity<ResidenceCheckResponse> submitResidence(@RequestBody ResidenceCheckRequest request) {
        ResidenceCheckResponse residenceCheck = sitterVerificationService.submitResidenceCheck(request.email(), request.address());
        if (!residenceCheck.success()) {
            return ResponseEntity.badRequest().body(residenceCheck);
        }
        return ResponseEntity.ok(residenceCheck);
    }

    @PostMapping("/emergency-check")
    public ResponseEntity<EmergencyCheckResponse> submitEmergency(@RequestBody EmergencyCheckRequest request) {
        EmergencyCheckResponse emergencyCheck = sitterVerificationService.submitEmergencyCheck(
                request.email(), request.name(), request.phoneNumber());
        if (!emergencyCheck.success()) {
            return ResponseEntity.badRequest().body(emergencyCheck);
        }
        return ResponseEntity.ok(emergencyCheck);
    }
}