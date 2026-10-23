package com.sittermatch.sittermatch.dto.profile;

import java.util.Set;

public record PetUpdateResult(
    Set<String> pets,
    String error
) {}
