package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.HomeownerCheck;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface HomeownerCheckRepository extends JpaRepository<HomeownerCheck, Integer> {
    List<HomeownerCheck> findByHomeownerId(Integer homeownerId);
}