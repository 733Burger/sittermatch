package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.Pet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PetRepository extends JpaRepository<Pet, Integer> {

    // Find all pets belonging to a specific homeowner
    List<Pet> findByHomeownerId(Integer homeownerId);

    // Find pets by species (e.g., "Dog", "Cat")
    List<Pet> findBySpecies(String species);
}