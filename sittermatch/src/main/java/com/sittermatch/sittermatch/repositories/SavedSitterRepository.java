package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.SavedSitter;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface SavedSitterRepository extends JpaRepository<SavedSitter, Integer> {
    List<SavedSitter> findByHomeownerId(Integer homeownerId);
    Optional<SavedSitter> findByHomeownerIdAndSitterId(Integer homeownerId, Integer sitterId);
    void deleteByHomeownerIdAndSitterId(Integer homeownerId, Integer sitterId);
}