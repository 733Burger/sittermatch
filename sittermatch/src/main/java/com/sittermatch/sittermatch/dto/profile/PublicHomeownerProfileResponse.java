package com.sittermatch.sittermatch.dto.profile;

import java.util.List;

public record PublicHomeownerProfileResponse(
        boolean success,
        String message,
        String name,
        String suburb,
        String city,
        String requirements,
        List<PublicPet> pets) {

    public record PublicPet(String name, String species, String breed, Integer age) {}

    public static PublicHomeownerProfileResponse failure(String message) {
        return new PublicHomeownerProfileResponse(
            false,
            message, 
            null, 
            null, 
            null, 
            null, 
            List.of()
        );
    }
}
