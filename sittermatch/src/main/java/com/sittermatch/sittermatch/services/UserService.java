package com.sittermatch.sittermatch.services;

import java.util.Optional;

import org.springframework.stereotype.Service;

import com.sittermatch.sittermatch.dto.RoleActionResponse;
import com.sittermatch.sittermatch.dto.UserRoleResponse;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.SitterRepository;
import com.sittermatch.sittermatch.repositories.UserRepository;

@Service 
public class UserService {
    private final UserRepository userRepository;
    private final SitterRepository sitterRepository;
    private final HomeownerRepository homeownerRepository;

    public UserService(UserRepository userRepository,
                       SitterRepository sitterRepository,
                       HomeownerRepository homeownerRepository) {
        this.userRepository = userRepository;
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
    }

    public UserRoleResponse getUserRoles(String email) {
        String cleanEmail = email.trim();
        Optional<User> found = userRepository.findByEmailIgnoreCase(cleanEmail);

        if (found.isEmpty()) {
            return new UserRoleResponse(false, false, false);
        }

        boolean hasSitterProfile = sitterRepository.findByUserEmail(cleanEmail).isPresent();
        boolean hasHomeownerProfile = homeownerRepository.findByUserEmail(cleanEmail).isPresent();

        return new UserRoleResponse(
            true,
            hasSitterProfile,
            hasHomeownerProfile
        );
    }

    public RoleActionResponse switchActiveRole(String email, String requestedRole) {
        String cleanEmail = email.trim();
        String cleanRole = requestedRole.trim().toUpperCase();
        boolean hasProfile;

        if (!cleanRole.equals("SITTER") && !cleanRole.equals("HOMEOWNER")) {
            return new RoleActionResponse(false, "Invalid role provided", null);
        }

        Optional<User> found = userRepository.findByEmailIgnoreCase(cleanEmail);
        if (found.isEmpty()) {
            return new RoleActionResponse(false, "User not found", null);
        }

        if (cleanRole.equals("SITTER")) {
            hasProfile = sitterRepository.findByUserEmail(cleanEmail).isPresent();
        } else {
            hasProfile = homeownerRepository.findByUserEmail(cleanEmail).isPresent();
        }

        if (!hasProfile) {
            return new RoleActionResponse(false, "No " + cleanRole + " profile exists for this user", null);
        }

        User user = found.get();
        user.setActiveRole(cleanRole);
        userRepository.save(user);

        return new RoleActionResponse(true, "Switched to " + cleanRole, cleanRole);
    }

    public RoleActionResponse addRole(String email, String requestedRole) {
        String cleanEmail = email.trim();
        String cleanRole = requestedRole.trim().toUpperCase();

        if (!cleanRole.equals("SITTER") && !cleanRole.equals("HOMEOWNER")) {
            return new RoleActionResponse(false, "Invalid Role provided", null);
        }

        Optional<User> found = userRepository.findByEmailIgnoreCase(cleanEmail);
        if (found.isEmpty()) {
            return new RoleActionResponse(false, "User not found", null);
        }

        User user = found.get();

        if (cleanRole.equals("SITTER")) {
            if (sitterRepository.findByUserEmail(cleanEmail).isPresent()) {
                return new RoleActionResponse(false, "Sitter profile already exists", null);
            }
            Sitter newSitter = new Sitter();
            newSitter.setUser(user);
            newSitter.setIsVerified(false);
            sitterRepository.save(newSitter);
        } else {
            if(homeownerRepository.findByUserEmail(cleanEmail).isPresent()) {
                return new RoleActionResponse(false, "Homeowner profile already exists", null);
            }
            Homeowner newHomeowner = new Homeowner();
            newHomeowner.setUser(user);
            newHomeowner.setIsVerified(false);
            homeownerRepository.save(newHomeowner);
        }

        user.setActiveRole(cleanRole);
        userRepository.save(user);

        return new RoleActionResponse(true, cleanRole + "profile created", cleanRole);
    }
}
