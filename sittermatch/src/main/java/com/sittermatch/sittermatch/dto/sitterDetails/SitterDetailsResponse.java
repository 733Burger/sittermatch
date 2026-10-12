package com.sittermatch.sittermatch.dto.sitterDetails;

import java.math.BigDecimal;
import java.util.List;

public record SitterDetailsResponse(
    boolean success,
    String message,
    String name,
    String email,
    String phone,
    String experience,
    Double dayRate,
    Double nightRate,
    Double rating,
    Integer totalReview,
    Boolean isVerified,
    List<ServiceItem> services,
    List<String> petPreferences
) {
    public interface SitterDetailsProjection  {
        String getName();
        String getEmail();
        String getPhone();
        String getExperience();
        Double getDayRate();
        Double getNightRate();
        Double getRating();
        Integer getTotalReview();
        Boolean getIsVerified(); 
    }

    public interface ServiceProjection {
        String getServiceType();
        BigDecimal getPrice();
    }

    public record ServiceItem(
        String serviceType,
        Double price
    ) {}

    public static SitterDetailsResponse getResponse(SitterDetailsProjection details, List<String> petPreferences, List<ServiceProjection> sitterServices) {
        return new SitterDetailsResponse(
            true,
            "Sitter details loaded",
            details.getName(),
            details.getEmail(),
            details.getPhone(),
            details.getExperience(),
            details.getDayRate(),
            details.getNightRate(),
            details.getRating(),
            details.getTotalReview(),
            details.getIsVerified(),
            sitterServices.stream()
                    .map(s -> new ServiceItem(s.getServiceType(), s.getPrice().doubleValue()))
                    .toList(),
            petPreferences
        );
    }

    public static SitterDetailsResponse failure(String message) {
        return new SitterDetailsResponse(
            false,
            message,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            List.of(),
            List.of()
        );
    }
}
