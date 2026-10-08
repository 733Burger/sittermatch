package com.sittermatch.sittermatch.controller;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestBody;

import com.sittermatch.sittermatch.model.SavedSitter;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.repository.SavedSitterRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;

@RestController
@RequestMapping("/api/saved-sitters")
@CrossOrigin(origins = "*") 
public class SavedSitterController {

    private final SavedSitterRepository savedSitterRepository;
    private final SitterRepository sitterRepository;

     
    public SavedSitterController(SavedSitterRepository savedSitterRepository, SitterRepository sitterRepository) {
        this.savedSitterRepository = savedSitterRepository;
        this.sitterRepository = sitterRepository;
    }

    // Save a sitter (Accept JSON Body)
    @PostMapping
    public ResponseEntity<?> saveSitter(@RequestBody Map<String, Integer> payload) {
        Integer homeownerId = payload.get("homeownerId");
        Integer sitterId = payload.get("sitterId");

        if (homeownerId == null || sitterId == null) {
            return ResponseEntity.badRequest().body("homeownerId and sitterId are required.");
        }

        // Prevent duplicate entries
        boolean exists = savedSitterRepository.findByHomeownerIdAndSitterId(homeownerId, sitterId).isPresent();
        if (!exists) {
            SavedSitter saved = new SavedSitter(homeownerId, sitterId);
            savedSitterRepository.save(saved);
        }

        return ResponseEntity.ok().build();
    }

    // Unsave/Remove a sitter
    @Transactional
    @DeleteMapping
    public ResponseEntity<?> removeSitter(@RequestParam Integer homeownerId, @RequestParam Integer sitterId) {
        savedSitterRepository.deleteByHomeownerIdAndSitterId(homeownerId, sitterId);
        return ResponseEntity.ok().build();
    }

    // Fetch all saved sitters for logged-in homeowner
    @GetMapping("/{homeownerId}")
    public List<Sitter> getSavedSitters(@PathVariable Integer homeownerId) {
        List<SavedSitter> savedList = savedSitterRepository.findByHomeownerId(homeownerId);
        List<Integer> sitterIds = savedList.stream()
                .map(SavedSitter::getSitterId)
                .collect(Collectors.toList());

        return sitterRepository.findAllById(sitterIds);
    }
}