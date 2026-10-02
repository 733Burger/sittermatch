package com.sittermatch.sittermatch.dto;

public record HomeownerCheckResponse(
    boolean succcess,
    String message,
    CheckTile idCheck,
    CheckTile addressCheck,
    CheckTile emergencyContactCheck
){
    public record CheckTile(String status, String subtitle) {}
}
