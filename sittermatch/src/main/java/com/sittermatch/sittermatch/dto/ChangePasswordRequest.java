package com.sittermatch.sittermatch.dto;


public record ChangePasswordRequest(String currentPassword, String newPassword) {}
