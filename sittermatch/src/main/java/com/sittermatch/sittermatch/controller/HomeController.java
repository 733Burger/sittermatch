package com.sittermatch.sittermatch.controller;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.sittermatch.sittermatch.dto.ResidenceCheckRequest;
import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckRequest;
import com.sittermatch.sittermatch.dto.verificationChecks.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.HomeownerCheckResponse;
import com.sittermatch.sittermatch.dto.verificationChecks.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.services.HomeService;


@RestController
@RequestMapping("/api/home")
@CrossOrigin(origins = "*")
public class HomeController {
    private final HomeService homeService;

    public HomeController(HomeService homeService) {
        this.homeService = homeService;
    }

    @GetMapping("/{homeownerId}/get-checks")
    public ResponseEntity<HomeownerCheckResponse> getChecks(@PathVariable int homeownerId) {
        HomeownerCheckResponse verificationCheck = homeService.getVerificationChecks(homeownerId);
        if (!verificationCheck.success()) {
            return ResponseEntity.badRequest().body(verificationCheck);
        }
        return ResponseEntity.ok(verificationCheck);
    }

    @PostMapping(value = "/identity-check", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<IdentityCheckSubmitResponse> submitIdentityCheck(
            @RequestParam("email") String email,
            @RequestParam("idPhoto") MultipartFile idPhoto) {
        IdentityCheckSubmitResponse identityCheck = homeService.submitIdentityCheck(email, idPhoto);
        if (!identityCheck.success()) {
            return ResponseEntity.badRequest().body(identityCheck);
        }
        return ResponseEntity.ok(identityCheck);
    }

    @PostMapping("/residence-check")
    public ResponseEntity<ResidenceCheckResponse> submitResidence(@RequestBody ResidenceCheckRequest request) {
        ResidenceCheckResponse residenceCheck = homeService.submitResidenceCheck(request.email(), request.address());
        if (!residenceCheck.success()) {
            return ResponseEntity.badRequest().body(residenceCheck);
        }
        return ResponseEntity.ok(residenceCheck);
    }

    @PostMapping("/emergency-check")
    public ResponseEntity<EmergencyCheckResponse> submitEmergency(@RequestBody EmergencyCheckRequest request) {
        EmergencyCheckResponse emergencyCheck = homeService.submitEmergencyCheck(
                request.email(), request.name(), request.phoneNumber());
        if (!emergencyCheck.success()) {
            return ResponseEntity.badRequest().body(emergencyCheck);
        }
        return ResponseEntity.ok(emergencyCheck);
    }
}