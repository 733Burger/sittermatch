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

import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

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
            return new LoginResponse(false, "Incorrect email or password", null, null, null);
        }

        User user = found.get();
        return new LoginResponse(
            true, 
            "Login successful. Welcome, " + user.getName() + "!", 
            user.getActiveRole(), 
            user.getEmail(),
            user.getId() 
        );
    }

    @Transactional
    public SignupResponse register(SignupRequest request) {
        String cleanEmail = request.email().trim().toLowerCase();
        String cleanRole = request.role().trim().toUpperCase();

        if (userRepository.existsByEmailIgnoreCase(cleanEmail)) {
            return new SignupResponse(false, "An account with this email already exists.");
        }

        if (!cleanRole.equals("SITTER") && !cleanRole.equals("HOMEOWNER")) {
            return new SignupResponse(false, "Invalid role specified.");
        }

        User user = new User();
        user.setName(request.fullName().trim());
        user.setEmail(cleanEmail);
        user.setPhone(request.phoneNumber().trim());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setActiveRole(cleanRole);
        user.setCreatedAt(LocalDateTime.now());

        try {
            User savedUser = userRepository.save(user);

            if (cleanRole.equals("SITTER")) {
                Sitter sitter = new Sitter();
                sitter.setUser(savedUser);
                sitter.setIsVerified(false);
                sitterRepository.save(sitter);
            } else if (cleanRole.equals("HOMEOWNER")) {
                Homeowner homeowner = new Homeowner();
                homeowner.setUser(savedUser);
                homeowner.setIsVerified(false);
                homeownerRepository.save(homeowner);
            }

            userRepository.flush();

            return new SignupResponse(true, "Registration successful!");
        } catch (DuplicateKeyException e) {
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
            return new SignupResponse(false, "An account with this email already exists.");
        } catch (Exception e) {
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
            return new SignupResponse(false, "An error occurred during registration: " + e.getMessage());
        }
    }
}