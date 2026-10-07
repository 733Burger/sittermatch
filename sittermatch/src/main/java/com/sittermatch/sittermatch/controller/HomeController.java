package com.sittermatch.sittermatch.controller;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.sittermatch.sittermatch.dto.EmergencyCheckRequest;
import com.sittermatch.sittermatch.dto.EmergencyCheckResponse;
import com.sittermatch.sittermatch.dto.HomeownerCheckResponse;
import com.sittermatch.sittermatch.dto.IdentityCheckSubmitResponse;
import com.sittermatch.sittermatch.dto.ResidenceCheckRequest;
import com.sittermatch.sittermatch.dto.ResidenceCheckResponse;
import com.sittermatch.sittermatch.services.HomeService;

@RestController
@RequestMapping("/api/home")
@CrossOrigin(origins = "*")
public class HomeController {
    private final HomeService homeService;

    public HomeController(HomeService homeService) {
        this.homeService = homeService;
    }

    @PostMapping(value = "/identity-check", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<IdentityCheckSubmitResponse> submitIdentityCheck(
            @RequestParam("email") String email,
            @RequestParam("idPhoto") MultipartFile idPhoto) {
        IdentityCheckSubmitResponse response = homeService.submitIdentityCheck(email, idPhoto);
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PostMapping("/residence-check")
    public ResponseEntity<ResidenceCheckResponse> submitResidence(@RequestBody ResidenceCheckRequest request) {
        ResidenceCheckResponse response = homeService.submitResidenceCheck(request.email(), request.address());
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PostMapping("/emergency-check")
    public ResponseEntity<EmergencyCheckResponse> submitEmergency(@RequestBody EmergencyCheckRequest request) {
        EmergencyCheckResponse response = homeService.submitEmergencyCheck(
                request.email(), request.name(), request.phoneNumber());
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{email:.+}/checks")
    public ResponseEntity<HomeownerCheckResponse> getChecks(@PathVariable String email) {
        HomeownerCheckResponse response = homeService.getVerificationChecks(email);
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }
}