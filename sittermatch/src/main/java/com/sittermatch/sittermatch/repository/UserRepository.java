package com.sittermatch.sittermatch.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sittermatch.sittermatch.model.User;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmailIgnoreCase(String email);
}
