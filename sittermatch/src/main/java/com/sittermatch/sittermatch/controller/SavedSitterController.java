package com.sittermatch.sittermatch.controller;

import java.util.List;
import java.util.Map;

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

import com.sittermatch.sittermatch.dto.savedSitterDetails.SavedSitterListResponse;
import com.sittermatch.sittermatch.dto.savedSitterDetails.ToggleSavedSitterRequest;
import com.sittermatch.sittermatch.dto.savedSitterDetails.ToggleSavedSitterResponse;
import com.sittermatch.sittermatch.model.SavedSitter;
import com.sittermatch.sittermatch.repository.SavedSitterRepository;
import com.sittermatch.sittermatch.services.SavedSitterService;

@RestController
@RequestMapping("/api/saved-sitters")
@CrossOrigin(origins = "*") 
public class SavedSitterController {

    private final SavedSitterService savedSitterService;
    private final SavedSitterRepository savedSitterRepository;

     
    public SavedSitterController(SavedSitterService savedSitterService, SavedSitterRepository savedSitterRepository) {
        this.savedSitterService = savedSitterService;
        this.savedSitterRepository = savedSitterRepository;
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

    @GetMapping("/{homeownerId}/get-saved-sitters")
    public ResponseEntity<List<SavedSitterListResponse>> getSavedSitters(@PathVariable int homeownerId) {
        List<SavedSitterListResponse> savedSitters = savedSitterService.getSavedSitters(homeownerId);
        if (savedSitters == null || savedSitters.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(savedSitters);
    }
    

    @PostMapping("/toggle-sitters")
    public ResponseEntity<ToggleSavedSitterResponse> toggleSitters(@RequestBody ToggleSavedSitterRequest request) {
        ToggleSavedSitterResponse result = savedSitterService.toggleSitter(request.homeownerId(), request.sitterId(), request.isCurrentlySaved());
        if (!result.success()) {
            return ResponseEntity.badRequest().body(result);
        }
        return ResponseEntity.ok(result);
    }

    // Unsave/Remove a sitter
    @Transactional
    @DeleteMapping
    public ResponseEntity<?> removeSitter(@RequestParam Integer homeownerId, @RequestParam Integer sitterId) {
        savedSitterRepository.deleteByHomeownerIdAndSitterId(homeownerId, sitterId);
        return ResponseEntity.ok().build();
    }

    // Fetch all saved sitters for logged-in homeowner
    // @GetMapping("/{homeownerId}")
    // public List<Sitter> getSavedSitters(@PathVariable Integer homeownerId) {
    //     List<SavedSitter> savedList = savedSitterRepository.findByHomeownerId(homeownerId);
    //     List<Integer> sitterIds = savedList.stream()
    //             .map(SavedSitter::getSitterId)
    //             .collect(Collectors.toList());

    //     return sitterRepository.findAllById(sitterIds);
    // }
}