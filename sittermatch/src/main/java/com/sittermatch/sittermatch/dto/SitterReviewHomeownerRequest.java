package com.sittermatch.sittermatch.dto;

public record SitterReviewHomeownerRequest (
   Integer bookingId,
   Integer homeownerId,
   Integer rating,
   String comments 
) {}
