package com.sittermatch.sittermatch.services;

import org.springframework.stereotype.Service;

import com.sittermatch.sittermatch.dto.UserRoleResponse;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.SitterRepository;

@Service 
public class UserService {
    private final SitterRepository sitterRepository;
    private final HomeownerRepository homeownerRepository;

    public UserService(SitterRepository sitterRepository,
                       HomeownerRepository homeownerRepository) {
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
    }

    public UserRoleResponse getUserRoles(String email) {
        String cleanEmail = email.trim();
        boolean hasSitterProfile = sitterRepository.findByUserEmail(cleanEmail).isPresent();
        boolean hasHomeownerProfile = homeownerRepository.findByUserEmail(cleanEmail).isPresent();

        return new UserRoleResponse(
            true,
            hasSitterProfile,
            hasHomeownerProfile
        );
    }
}
