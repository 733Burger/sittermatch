package com.sittermatch.sittermatch.services;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.sittermatch.sittermatch.dto.AddPetRequest;
import com.sittermatch.sittermatch.dto.PetDto;
import com.sittermatch.sittermatch.dto.PetResponse;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Pet;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.PetRepository;

@Service
public class PetService {
    
    private static final Set<String> SPECIES =
        Set.of("LARGE DOG", "SMALL DOG", "CAT", "BIRD", "REPTILE", "FISH", "EXOTIC");

    private final PetRepository petRepository;
    private final HomeownerRepository homeownerRepository;

    public PetService(PetRepository petRepository, HomeownerRepository homeownerRepository) {
        this.petRepository = petRepository;
        this.homeownerRepository = homeownerRepository;
    }

    public List<PetDto> getPets(Integer homeownerId) {
        return petRepository.findByHomeownerId(homeownerId).stream().map(this::toDto).toList();
    }

    @Transactional
    public PetResponse addPet(Integer homeownerId, AddPetRequest req) {
        Optional<Homeowner> homeowner = homeownerRepository.findById(homeownerId);
        if (homeowner.isEmpty()) {
            return PetResponse.failure("Homeowner not found");
        }

        String name = req.name() == null ? "" : req.name().trim();
        String breed = req.breed() == null ? "" : req.breed().trim();
        String species = req.species() == null ? "" : req.species().trim().toUpperCase();
        String careNotes = req.careNotes() == null ? "" : req.careNotes().trim();
        Integer age = req.age();

        String error = validate(name, breed, species, age, careNotes);
        if (error != null) {
            return PetResponse.failure(error);
        }

        Pet pet = new Pet();
        pet.setHomeowner(homeowner.get());
        pet.setName(name);
        pet.setBreed(breed);
        pet.setSpecies(species);
        pet.setAge(age);
        pet.setCareNotes(careNotes);
        pet.setTotalReviews(0);   // set explicitly: a null here would override the column default

        return new PetResponse(true, "Pet added", toDto(petRepository.save(pet)));
    }

    private PetDto toDto(Pet p) {
        return new PetDto(p.getId(), p.getName(), p.getSpecies(), p.getBreed(), p.getAge(),
                p.getCareNotes(), p.getBehaviourScore(), p.getTotalReviews(), p.getImageUrl());
    }

    private String validate(String name, String breed, String species, Integer age, String careNotes) {
    if (name.isBlank() || name.length() > 255) return "Enter a pet name under 255 characters.";
    if (breed.isBlank() || breed.length() > 255) return "Enter a breed under 255 characters.";
    if (species.isBlank() || species.length() > 255) return "Enter a pet type under 255 characters.";
    if (age == null || age < 0 || age > 40) return "Enter an age between 0 and 40.";
    if (!SPECIES.contains(species)) return "Select a valid pet type.";
    return null;
}

@Transactional
public PetResponse updatePet(Integer homeownerId, Integer petId, AddPetRequest req) {
    Optional<Pet> found = petRepository.findById(petId);
    if (found.isEmpty() || !found.get().getHomeowner().getId().equals(homeownerId)) {
        return PetResponse.failure("Pet not found");
    }

    String name = req.name() == null ? "" : req.name().trim();
    String breed = req.breed() == null ? "" : req.breed().trim();
    String species = req.species() == null ? "" : req.species().trim().toUpperCase();
    String careNotes = req.careNotes() == null ? "" : req.careNotes().trim();

    String error = validate(name, breed, species, req.age(), careNotes);
    if (error != null) {
        return PetResponse.failure(error);
    }

    Pet pet = found.get();
    pet.setName(name);
    pet.setBreed(breed);
    pet.setSpecies(species);
    pet.setAge(req.age());
    pet.setCareNotes(careNotes);

    return new PetResponse(true, "Pet updated", toDto(petRepository.save(pet)));
}

@Transactional
public PetResponse deletePet(Integer homeownerId, Integer petId) {
    Optional<Pet> found = petRepository.findById(petId);
    if (found.isEmpty() || !found.get().getHomeowner().getId().equals(homeownerId)) {
        return PetResponse.failure("Pet not found");
    }
    petRepository.delete(found.get());
    return new PetResponse(true, "Pet deleted", null);
}
}