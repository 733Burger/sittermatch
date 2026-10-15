package com.sittermatch.sittermatch.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.sittermatch.sittermatch.dto.AddPetRequest;
import com.sittermatch.sittermatch.dto.PetDto;
import com.sittermatch.sittermatch.dto.PetResponse;
import com.sittermatch.sittermatch.services.PetService;

@RestController
@RequestMapping("/api/pets")
@CrossOrigin(origins = "*")
public class PetController {
    private final PetService petService;

    public PetController(PetService petService) {
        this.petService = petService;
    }

    @GetMapping("/homeowner/{homeownerId}")
    public List<PetDto> getPets(@PathVariable Integer homeownerId) {
        return petService.getPets(homeownerId);
    }

    @PostMapping("/homeowner/{homeownerId}")
    public ResponseEntity<PetResponse> addPet(@PathVariable Integer homeownerId,
                                              @RequestBody AddPetRequest request) {
        PetResponse response = petService.addPet(homeownerId, request);
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/homeowner/{homeownerId}/{petId}")
    public ResponseEntity<PetResponse> updatePet(@PathVariable Integer homeownerId,
                                                @PathVariable Integer petId,
                                                @RequestBody AddPetRequest request) {
        PetResponse response = petService.updatePet(homeownerId, petId, request);
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/homeowner/{homeownerId}/{petId}")
    public ResponseEntity<PetResponse> deletePet(@PathVariable Integer homeownerId,
                                                @PathVariable Integer petId) {
        PetResponse response = petService.deletePet(homeownerId, petId);
        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }
        return ResponseEntity.ok(response);
    }
}
