package com.sittermatch.sittermatch.dto;

public record UpdateProfileRequest(
        String name,
        String email,
        String phone,
        String address,
        String requirements,
        String placeId,
        String sessionToken) {}
