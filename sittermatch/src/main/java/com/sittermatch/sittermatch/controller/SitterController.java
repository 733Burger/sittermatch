package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.SitterResponseDTO;
import com.sittermatch.sittermatch.repositories.SitterRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/sitters")
public class SitterController {

    private final SitterRepository sitterRepository;

    public SitterController(SitterRepository sitterRepository) {
        this.sitterRepository = sitterRepository;
    }

    @GetMapping
    public ResponseEntity<List<SitterResponseDTO>> getAllSitters() {
        List<SitterResponseDTO> sitters = sitterRepository.findAll().stream()
            .map(sitter -> new SitterResponseDTO(
                sitter.getId(),
                sitter.getUser() != null ? sitter.getUser().getName() : null,
                sitter.getUser() != null ? sitter.getUser().getEmail() : null,
                sitter.getUser() != null ? sitter.getUser().getPhone() : null,
                sitter.getRating(),
                sitter.getTotalReviews(),
                sitter.getDayRate(),
                sitter.getNightRate(),
                sitter.getExperience(),
                sitter.getServiceTypes() != null ? sitter.getServiceTypes() : Set.of(),
                sitter.getPetTypes() != null ? sitter.getPetTypes() : Set.of(),
                sitter.getIsVerified()
            ))
            .toList();

        return ResponseEntity.ok(sitters);
    }
}