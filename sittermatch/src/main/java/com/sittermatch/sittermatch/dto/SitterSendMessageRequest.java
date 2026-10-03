package com.sittermatch.sittermatch.dto;

public record SitterSendMessageRequest (
    Integer homeownerId,
    String sentBy,
    String content
) {}
