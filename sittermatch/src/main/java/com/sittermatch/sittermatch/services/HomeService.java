package com.sittermatch.sittermatch.services;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.sittermatch.sittermatch.dto.HomeownerCheckResponse;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.HomeownerCheck;
import com.sittermatch.sittermatch.model.HomeownerVerification;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.HomeownerVerificationRepository;
import com.sittermatch.sittermatch.repositories.UserRepository;

@Service 
public class HomeService {
    private final HomeownerRepository homeownerRepository;
    private final HomeownerVerificationRepository homeownerVerificationRepository;

    public HomeService(HomeownerRepository homeownerRepository,
                       HomeownerVerificationRepository homeownerVerificationRepository) {
        this.homeownerRepository = homeownerRepository;
        this.homeownerVerificationRepository = homeownerVerificationRepository;
    }

    public HomeownerCheckResponse getVerification(String email) {
        String cleanEmail = email.trim();

        if (cleanEmail == null || cleanEmail.isBlank()) {
            return new HomeownerCheckResponse(
                false,
                "Email cannot be null or blank",
                new HomeownerCheckResponse.CheckTile("error", "Email is required"),
                new HomeownerCheckResponse.CheckTile("error", "Email is required"),
                new HomeownerCheckResponse.CheckTile("error", "Email is required")
            );
        }

        Optional<Homeowner> homeowner = homeownerRepository.findByUserEmail(cleanEmail);

        if (homeowner.isEmpty()) {
            return new HomeownerCheckResponse(
                false,
                "Homeowner not found",
                new HomeownerCheckResponse.CheckTile("error", "Homeowner not found"),
                new HomeownerCheckResponse.CheckTile("error", "Homeowner not found"),
                new HomeownerCheckResponse.CheckTile("error", "Homeowner not found")
            );
        }

        Optional<HomeownerVerification> checks = homeownerVerificationRepository.findByHomeownerId(homeowner.get().getId());
        if (checks.isEmpty()) {
            return new HomeownerCheckResponse(
                false,
                "No checks found for this homeowner",
                new HomeownerCheckResponse.CheckTile("incomplete", "No checks found"),
                new HomeownerCheckResponse.CheckTile("incomplete", "No checks found"),
                new HomeownerCheckResponse.CheckTile("incomplete", "No checks found")
            );
        } else {
            HomeownerVerification check = checks.get();
            return new HomeownerCheckResponse(
                true,
                "Checks retrieved successfully",
                new HomeownerCheckResponse.CheckTile("success", check.getIdNumberHash()),
                new HomeownerCheckResponse.CheckTile("success", check.getIdDocumentPath()),
                new HomeownerCheckResponse.CheckTile("success", check.getRejectionReason())
            );
        }
    }
}
