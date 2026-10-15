package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Integer> {

    // Every message between one sitter and one homeowner, oldest first.
    @Query("SELECT m FROM Message m WHERE m.sitter.id = :sitterId AND m.homeowner.id = :homeownerId ORDER BY m.sentAt ASC")
    List<Message> findBySitterIdAndHomeownerIdOrderBySentAtAsc(
        @Param("sitterId") Integer sitterId, 
        @Param("homeownerId") Integer homeownerId
    );

    // Every message a sitter is part of, newest first (used to build their conversation list).
    @Query("SELECT m FROM Message m WHERE m.sitter.id = :userId ORDER BY m.sentAt DESC")
    List<Message> findAllForSitter(@Param("userId") Integer userId);

    // Every message a homeowner is part of, newest first.
    @Query("SELECT m FROM Message m WHERE m.homeowner.id = :userId ORDER BY m.sentAt DESC")
    List<Message> findAllForHomeowner(@Param("userId") Integer userId);

    // Marks the other person's messages in a conversation as read.
    @Modifying(clearAutomatically = true)
    @Query("UPDATE Message m SET m.isRead = true "
            + "WHERE m.sitter.id = :sitterId AND m.homeowner.id = :homeownerId "
            + "AND m.sentBy = :sentBy AND m.isRead = false")
    int markRead(@Param("sitterId") Integer sitterId,
                 @Param("homeownerId") Integer homeownerId,
                 @Param("sentBy") String sentBy);
}