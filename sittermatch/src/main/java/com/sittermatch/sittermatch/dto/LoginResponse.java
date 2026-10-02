package com.sittermatch.sittermatch.dto;

public record LoginResponse(
    boolean success,
    String message,
    String role,
    String email,
    Integer userId 
) {}