package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.SitterCheck;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SitterCheckRepository extends JpaRepository<SitterCheck, Integer> {
    List<SitterCheck> findBySitterId(Integer sitterId);
}