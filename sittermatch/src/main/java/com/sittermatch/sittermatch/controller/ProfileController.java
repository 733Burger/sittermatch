package com.sittermatch.sittermatch.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sittermatch.sittermatch.dto.ProfileResponse;
import com.sittermatch.sittermatch.dto.SitterProfileResponse;
import com.sittermatch.sittermatch.dto.SitterProfileUpdateRequest;
import com.sittermatch.sittermatch.dto.UpdateProfileRequest;
import com.sittermatch.sittermatch.services.ProfileService;

@RestController 
@RequestMapping ("/api/profile")
@CrossOrigin (origins = "*")
public class ProfileController {
    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/get-profile/{userId}")
    public ResponseEntity<ProfileResponse> getProfile(@PathVariable Integer userId) {
        ProfileResponse profile = profileService.getProfile(userId);
        if (!profile.success()) {
            return ResponseEntity.badRequest().body(profile);
        }
        return ResponseEntity.ok(profile);
    }

    @PutMapping("/update-profile/{userId}")
    public ResponseEntity<ProfileResponse> updateProfile(@PathVariable Integer userId, @RequestBody UpdateProfileRequest request) {
        ProfileResponse profile = profileService.updateProfile(userId, request);
        if (!profile.success()) {
            return ResponseEntity.badRequest().body(profile);
        }
        return ResponseEntity.ok(profile);
    }

    @GetMapping("/get-sitter-profile/{userId}")
    public ResponseEntity<SitterProfileResponse> getSitterProfile(@PathVariable Integer userId) {
        SitterProfileResponse profile = profileService.getSitterProfile(userId);
        if (!profile.success()) {
            return ResponseEntity.badRequest().body(profile);
        }
        return ResponseEntity.ok(profile);
    }

    @PutMapping("/update-sitter-profile/{userId}")
    public ResponseEntity<SitterProfileResponse> updateSitterProfile(@PathVariable Integer userId, @RequestBody SitterProfileUpdateRequest request) {
        SitterProfileResponse profile = profileService.updateSitterProfile(userId, request);
        if (!profile.success()) {
            return ResponseEntity.badRequest().body(profile);
        }
        return ResponseEntity.ok(profile);
    }
}
