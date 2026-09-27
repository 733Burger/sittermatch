package com.sittermatch.sittermatch.dto;

public record UserRoleResponse (
    boolean success,
    boolean hasSitterProfile,
    boolean hasHomeownerProfile
) {}
