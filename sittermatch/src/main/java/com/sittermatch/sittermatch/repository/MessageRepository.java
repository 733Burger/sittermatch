package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Integer> {

    // Retrieve the chat thread between a specific sitter and homeowner ordered by timestamp
    List<Message> findBySitterIdAndHomeownerIdOrderBySentAtAsc(Integer sitterId, Integer homeownerId);

    // Find all messages involving a specific sitter
    List<Message> findBySitterId(Integer sitterId);

    // Find all messages involving a specific homeowner
    List<Message> findByHomeownerId(Integer homeownerId);
}
