package com.sittermatch.sittermatch.dto;

import java.time.LocalDateTime;

/**
 * A checklist task. On a booking, done and checkedAt say whether the sitter ticked it off on that day;
 * on the homeowner's profile they are always false and null.
 */
public record TaskResponse(Integer id, String title, String note, boolean done, LocalDateTime checkedAt) {}
