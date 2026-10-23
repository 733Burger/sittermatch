package com.sittermatch.sittermatch.dto.profile;

import java.util.Set;

import com.sittermatch.sittermatch.model.SitterServices;

public record ServiceUpdateResult(
    Set<SitterServices> services,
    Double nightRate,
    String error
) {}
