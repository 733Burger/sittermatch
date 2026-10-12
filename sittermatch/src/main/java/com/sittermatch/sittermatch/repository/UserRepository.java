package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Integer> {
    
    Optional<User> findByEmailIgnoreCase(String email);

    long countByActiveRoleNot(String activeRole);

    Boolean existsByEmailIgnoreCase(String email);

    List<User> findByActiveRole(String activeRole);
}