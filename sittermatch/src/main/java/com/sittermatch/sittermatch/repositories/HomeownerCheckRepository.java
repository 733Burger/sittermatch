package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.HomeownerCheck;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface HomeownerCheckRepository extends JpaRepository<HomeownerCheck, Integer> {
    List<HomeownerCheck> findByHomeownerId(Integer homeownerId);

    Optional<HomeownerCheck> findByHomeownerIdAndType(Integer homeownerId, String type);

}