package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;


public interface UserRepository extends JpaRepository<User, Integer> {
    
   Optional<User> findByEmailIgnoreCase(String email);

    Boolean existsByEmailIgnoreCase(String email);

    List<User> findByActiveRole(String activeRole);
}