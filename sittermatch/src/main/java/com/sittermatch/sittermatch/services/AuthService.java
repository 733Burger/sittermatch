package com.sittermatch.sittermatch.services;

import com.sittermatch.sittermatch.dto.LoginRequest;
import com.sittermatch.sittermatch.dto.LoginResponse;
import com.sittermatch.sittermatch.dto.SignupRequest;
import com.sittermatch.sittermatch.dto.SignupResponse;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repositories.HomeownerRepository;
import com.sittermatch.sittermatch.repositories.SitterRepository;
import com.sittermatch.sittermatch.repositories.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final SitterRepository sitterRepository;
    private final HomeownerRepository homeownerRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository,
                       SitterRepository sitterRepository,
                       HomeownerRepository homeownerRepository,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public LoginResponse login(LoginRequest request) {
        Optional<User> found = userRepository.findByEmailIgnoreCase(request.email().trim());

        if (found.isEmpty() || !passwordEncoder.matches(request.password(), found.get().getPassword())) {
            return new LoginResponse(false, "Incorrect email or password", null, null);
        }

        User user = found.get();
        return new LoginResponse(
            true, 
            "Login successful. Welcome, " + user.getName() + "!", 
            user.getActiveRole(), 
            user.getEmail()
        );
    }

    @Transactional
    public SignupResponse register(SignupRequest request) {
        String cleanEmail = request.email().trim().toLowerCase();

        if (userRepository.existsByEmailIgnoreCase(cleanEmail)) {
            return new SignupResponse(false, "An account with this email already exists.");
        }

        User user = new User();
        user.setName(request.fullName().trim());
        user.setEmail(cleanEmail);
        user.setPhone(request.phoneNumber().trim());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setActiveRole(request.role().toUpperCase());
        user.setCreatedAt(LocalDateTime.now());

        User savedUser = userRepository.save(user);

        // Save profile record based on chosen role
        if ("SITTER".equalsIgnoreCase(request.role())) {
            Sitter sitter = new Sitter();
            sitter.setUser(savedUser);
            sitter.setIsVerified(false);
            sitterRepository.save(sitter);
        } else if ("HOMEOWNER".equalsIgnoreCase(request.role())) {
            Homeowner homeowner = new Homeowner();
            homeowner.setUser(savedUser);
            homeowner.setIsVerified(false);
            homeownerRepository.save(homeowner);
        }

        return new SignupResponse(true, "Registration successful!");
    }
}