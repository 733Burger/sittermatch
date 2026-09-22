package com.sittermatch.sittermatch.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sittermatch.sittermatch.dto.LoginRequest;
import com.sittermatch.sittermatch.dto.LoginResponse;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repository.UserRepository;

import jakarta.validation.Valid;

import java.util.Map;
import java.util.Optional;

import javax.security.auth.login.AppConfigurationEntry.LoginModuleControlFlag;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@RestController 
@RequestMapping("/api/auth")
public class AuthController {
    
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;

    public AuthController(UserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        Optional<User> found = users.findByEmailIgnoreCase(request.email().trim());

        if (found.isEmpty() || !passwordEncoder.matches(request.password(), found.get().getPassword())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Incorrect email or password"));
        }

        User user = found.get();
        return ResponseEntity.ok(new LoginResponse(
                true, "Login successful. Welcome, " + user.getName() + "!"));
    }

}
