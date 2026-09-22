package com.sittermatch.sittermatch.repositories;

import com.sittermatch.sittermatch.model.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;


public interface UserRepository extends JpaRepository<User, Integer> {
    
    // Find user by unique email address (essential for authentication & login)
    Optional<User> findByEmail(String email);

    // Check if an email already exists during registration
    Boolean existsByEmail(String email);

    // Find users by active role (e.g., "SITTER", "HOMEOWNER", "BOTH")
    List<User> findByActiveRole(String activeRole);
}