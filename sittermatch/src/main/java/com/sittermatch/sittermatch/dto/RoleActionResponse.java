package com.sittermatch.sittermatch.dto;

public record RoleActionResponse (
    boolean success,
    String message,
    String activeRole
) {}
