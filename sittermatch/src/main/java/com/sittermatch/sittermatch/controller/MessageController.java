package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Message;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.MessageRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    // Longest message accepted. Change this if your `message` column is longer than 255.
    private static final int MAX_LENGTH = 255;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SitterRepository sitterRepository;

    @Autowired
    private HomeownerRepository homeownerRepository;

    // ---------- What the app sends and receives ----------

    public record MessageDto(
            Integer id,
            Integer sitterId,
            Integer homeownerId,
            String sentBy,
            String message,
            String sentAt,
            boolean isRead) {}

    public record ConversationDto(
            Integer partnerId,
            String partnerName,
            String lastMessage,
            String lastSentAt,
            int unreadCount) {}

    public record SendMessageRequest(
            Integer sitterId,
            Integer homeownerId,
            String sentBy,
            String message) {}

    private MessageDto toDto(Message m) {
        return new MessageDto(
                m.getId(),
                m.getSitter() != null ? m.getSitter().getId() : null,
                m.getHomeowner() != null ? m.getHomeowner().getId() : null,
                m.getSentBy(),
                m.getMessage(),
                m.getSentAt() != null ? m.getSentAt().toString() : "",
                Boolean.TRUE.equals(m.getIsRead()));
    }

    // ---------- Conversation list ----------

    /**
     * Everyone this user has exchanged messages with, newest conversation first.
     * role is the viewer's role: SITTER or HOMEOWNER.
     */
    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationDto>> getConversations(
            @RequestParam Integer userId,
            @RequestParam String role) {

        boolean isSitter = "SITTER".equalsIgnoreCase(role);
        List<Message> all = isSitter
                ? messageRepository.findAllForSitter(userId)
                : messageRepository.findAllForHomeowner(userId);

        // `all` is newest first, so the first message we see per person is the latest one.
        Map<Integer, Message> lastByPartner = new LinkedHashMap<>();
        Map<Integer, Integer> unreadByPartner = new HashMap<>();

        for (Message m : all) {
            int partnerId = isSitter 
                ? m.getHomeowner().getId() 
                : m.getSitter().getId();
            
            lastByPartner.putIfAbsent(partnerId, m);

            boolean fromPartner = !m.getSentBy().equalsIgnoreCase(role);
            if (fromPartner && !Boolean.TRUE.equals(m.getIsRead())) {
                unreadByPartner.merge(partnerId, 1, Integer::sum);
            }
        }

        List<ConversationDto> result = new ArrayList<>();
        for (Map.Entry<Integer, Message> entry : lastByPartner.entrySet()) {
            Message last = entry.getValue();
            String name = userRepository.findById(entry.getKey())
                    .map(User::getName)
                    .orElse("Unknown");
            String preview = (last.getSentBy().equalsIgnoreCase(role) ? "You: " : "") + last.getMessage();

            result.add(new ConversationDto(
                    entry.getKey(),
                    name,
                    preview,
                    last.getSentAt().toString(),
                    unreadByPartner.getOrDefault(entry.getKey(), 0)));
        }

        return ResponseEntity.ok(result);
    }

    // ---------- One conversation ----------

    /**
     * All messages between a sitter and a homeowner, oldest first.
     * Opening the thread marks the other person's messages as read.
     * viewerRole is the role of the person who is looking at the chat.
     */
    @Transactional
    @GetMapping("/thread")
    public ResponseEntity<List<MessageDto>> getThread(
            @RequestParam Integer sitterId,
            @RequestParam Integer homeownerId,
            @RequestParam String viewerRole) {

        String otherPerson = "SITTER".equalsIgnoreCase(viewerRole) ? "HOMEOWNER" : "SITTER";
        messageRepository.markRead(sitterId, homeownerId, otherPerson);

        List<MessageDto> thread = messageRepository
                .findBySitterIdAndHomeownerIdOrderBySentAtAsc(sitterId, homeownerId)
                .stream()
                .map(this::toDto)
                .toList();

        return ResponseEntity.ok(thread);
    }

    // ---------- Send ----------

    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> send(@RequestBody SendMessageRequest request) {
        String text = request.message() == null ? "" : request.message().trim();
        String sentBy = request.sentBy() == null ? "" : request.sentBy().trim().toUpperCase();

        if (request.sitterId() == null || request.homeownerId() == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "message", "Missing sitter or homeowner."));
        }
        if (!sentBy.equals("SITTER") && !sentBy.equals("HOMEOWNER")) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "message", "Invalid sender."));
        }
        if (text.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "message", "Message cannot be empty."));
        }
        if (text.length() > MAX_LENGTH) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "message", "Message is too long (max " + MAX_LENGTH + " characters)."));
        }
        if (!sitterRepository.existsById(request.sitterId())
                || !homeownerRepository.existsById(request.homeownerId())) {
            return ResponseEntity.status(404)
                    .body(Map.of("success", false, "message", "Sitter or homeowner not found."));
        }

        Sitter sitterObj = sitterRepository.findById(request.sitterId()).orElse(null);
        Homeowner homeownerObj = homeownerRepository.findById(request.homeownerId()).orElse(null);

        if (sitterObj == null || homeownerObj == null) {
            return ResponseEntity.status(404)
                    .body(Map.of("success", false, "message", "Sitter or homeowner not found."));
        }

        Message m = new Message();
        m.setSitter(sitterObj);
        m.setHomeowner(homeownerObj);
        m.setSentBy(sentBy);
        m.setMessage(text);
        m.setSentAt(LocalDateTime.now());
        m.setIsRead(false);

        Message saved = messageRepository.save(m);

        return ResponseEntity.ok(Map.of("success", true, "message", toDto(saved)));
    }
}