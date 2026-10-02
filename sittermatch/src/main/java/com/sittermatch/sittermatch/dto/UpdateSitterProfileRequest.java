package com.sittermatch.sittermatch.dto;

import java.util.Set;

public record UpdateSitterProfileRequest (
    Double dayRate,
    Double nightRate,
    Integer experience,
    Set<String> prefrences,
    Set<String> services
) {}
