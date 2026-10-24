package com.sittermatch.sittermatch.dto;

/** A checklist task the homeowner adds or edits on their profile. */
public record TaskRequest(String title, String note) {}
