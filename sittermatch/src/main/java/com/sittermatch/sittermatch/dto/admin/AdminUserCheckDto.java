package com.sittermatch.sittermatch.dto.admin;

public record AdminUserCheckDto(
    Long id,
    String userName,
    String role,
    String checkType,
    String detail,
    String submittedOn
) {}