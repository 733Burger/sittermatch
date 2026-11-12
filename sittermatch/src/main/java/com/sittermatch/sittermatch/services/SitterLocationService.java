package com.sittermatch.sittermatch.services;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.sittermatch.sittermatch.dto.sitterDetails.SitterListResponse;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.SavedSitterRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;

@Service
public class SitterLocationService {
    private static final double EARTH_RADIUS_KM = 6371.0;
    private static final double DEFAULT_RADIUS_KM = 40.0;
    private static final double ANY_DISTANCE_KM = 1000.0; // a radius this big means "at any distance"
    private static final int MAX_RESULTS = 50;

    private final SitterRepository sitterRepository;
    private final HomeownerRepository homeownerRepository;
    private final SavedSitterRepository savedSitterRepository;

    public SitterLocationService(SitterRepository sitterRepository,
            HomeownerRepository homeownerRepository,
            SavedSitterRepository savedSitterRepository) {
        this.sitterRepository = sitterRepository;
        this.homeownerRepository = homeownerRepository;
        this.savedSitterRepository = savedSitterRepository;
    }

    //Finds sitters near the homeowner's saved home address, nearest first.
    //If the homeowner has no saved coordinates yet, every sitter is returned
    //(the old behaviour) so the home page is never empty for new accounts.
    @Transactional(readOnly = true)
    public List<SitterListResponse> findNearbySitters(int homeownerId, Double requestedRadiusKm) {
        if (homeownerId <= 0) {
            return List.of();
        }

        Set<Integer> savedSitterIds = savedSitterRepository
                .findByHomeownerId(homeownerId)
                .stream()
                .map(savedSitter -> savedSitter.getSitterId())
                .collect(Collectors.toSet());

        // A user can be both a homeowner and a sitter, so leave them out of their own results.
        List<Sitter> sitters = sitterRepository.findAll().stream().filter(sitter -> sitter.getId() != homeownerId).toList();

        Homeowner homeowner = homeownerRepository.findById(homeownerId).orElse(null);
        if (homeowner == null || homeowner.getLatitude() == null || homeowner.getLongitude() == null) {
            return sitters.stream().map(sitter -> toSitterListResponse(sitter, savedSitterIds.contains(sitter.getId()), null)).toList();
        }

        double homeLat = homeowner.getLatitude().doubleValue();
        double homeLng = homeowner.getLongitude().doubleValue();
        double radiusKm = (requestedRadiusKm != null && requestedRadiusKm > 0) ? requestedRadiusKm : DEFAULT_RADIUS_KM;
        boolean isAnyDistance = radiusKm >= ANY_DISTANCE_KM;

        List<SitterListResponse> nearby = new ArrayList<>();
        for (Sitter sitter : sitters) {

            // Sitters who haven't picked their area yet can't be placed on the map.
            if (sitter.getLatitude() == null || sitter.getLongitude() == null) {
                continue;
            }

            double distance = haversineKm(homeLat, homeLng,
                    sitter.getLatitude().doubleValue(), sitter.getLongitude().doubleValue());
            if (!isAnyDistance && distance > radiusKm) {
                continue;
            }

            double roundedDistance = Math.round(distance * 10.0) / 10.0;
            nearby.add(toSitterListResponse(sitter, savedSitterIds.contains(sitter.getId()), roundedDistance));
        }

        nearby.sort(Comparator.comparingDouble(sitter -> sitter.distanceKm() != null ? sitter.distanceKm() : Double.MAX_VALUE));
        return nearby.size() > MAX_RESULTS ? nearby.subList(0, MAX_RESULTS) : nearby;
    }

    //Haversine formula: straight-line distance in km between two points on Earth.
    static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    private SitterListResponse toSitterListResponse(Sitter sitter, boolean isSaved, Double distanceKm) {
        var sitterUserDetails = sitter.getUser();
        return new SitterListResponse(
                sitter.getId(),
                (sitterUserDetails != null) ? sitterUserDetails.getName() : null,
                sitter.getRating(),
                sitter.getTotalReviews(),
                sitter.getDayRate(),
                sitter.getNightRate(),
                sitter.getIsVerified(),
                isSaved,
                sitter.getSuburb(),
                distanceKm,
                // Sent so the home screen filter chips can match on what the sitter offers.
                sitter.getServices().stream().map(service -> service.getServiceType()).toList(),
                List.copyOf(sitter.getPetPreferences()));
    }
}
