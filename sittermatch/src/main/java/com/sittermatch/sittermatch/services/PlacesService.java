package com.sittermatch.sittermatch.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

@Service
public class PlacesService {

    private static final Logger log = LoggerFactory.getLogger(PlacesService.class);
    private static final String BASE_URL = "https://places.googleapis.com/v1";

    private static final Pattern PLACE_ID = Pattern.compile("^[A-Za-z0-9_-]{10,300}$");
    private static final Pattern SESSION_TOKEN = Pattern.compile("^[A-Za-z0-9_-]{8,36}$");

    private final RestTemplate restTemplate = new RestTemplate();
    private final String apiKey;

    public PlacesService(@Value("${app.google.maps-api-key}") String apiKey) {
        this.apiKey = apiKey;
    }

    public record Suggestion(String placeId, String description) {}

    public record PlaceLocation(
        double latitude,
        double longitude,
        String formattedAddress,
        String suburb,
        String city
    ) {}

    public List<Suggestion> autocomplete(String input, String sessionToken) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("Google Maps API key is not set. Set GOOGLE_MAPS_API_KEY before searching addresses.");
            return List.of();
        }

        String text = input == null ? "" : input.trim();
        if (text.length() < 3 || text.length() > 200) {
            return List.of();
        }

        Map<String, Object> body = new HashMap<>();
        body.put("input", text);
        body.put("includedRegionCodes", List.of("za"));
        if (isValidSessionToken(sessionToken)) {
            body.put("sessionToken", sessionToken);
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-Goog-Api-Key", apiKey);

        try {
            Map<?, ?> root = restTemplate.postForObject(BASE_URL + "/places:autocomplete", new HttpEntity<>(body, headers), Map.class);

            List<Suggestion> suggestions = new ArrayList<>();

            if (root != null && root.get("suggestions") instanceof List<?> items) {
                for (Object item : items) {
                    if (!(item instanceof Map<?, ?> itemMap)) continue;
                    if (!(itemMap.get("placePrediction") instanceof Map<?, ?> prediction)) continue;

                    String placeId = asText(prediction.get("placeId"));
                    String description = "";

                    if (prediction.get("text") instanceof Map<?, ?> textMap) {
                        description = asText(textMap.get("text"));
                    }

                    if (!placeId.isEmpty() && !description.isEmpty()) {
                        suggestions.add(new Suggestion(placeId, description));
                    }
                }
            }
            return suggestions;
        } catch (RestClientException e) {
            log.warn("Places autocomplete failed: {}", e.getClass().getSimpleName());
            return List.of();
        }
    }

    public Optional<PlaceLocation> getLocation(String placeId, String sessionToken) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("Google Maps API key is not set. Set GOOGLE_MAPS_API_KEY before looking up a place.");
            return Optional.empty();
        }

        if (placeId == null || !PLACE_ID.matcher(placeId).matches()) {
            return Optional.empty();
        }

        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(BASE_URL + "/places/{placeId}");
        if (isValidSessionToken(sessionToken)) {
            builder.queryParam("sessionToken", sessionToken);
        }

        URI uri = builder.buildAndExpand(placeId).encode().toUri();
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Goog-Api-Key", apiKey);
        headers.set("X-Goog-FieldMask", "location,formattedAddress,addressComponents");

        try {
            Map<?, ?> root = restTemplate.exchange(uri, HttpMethod.GET, new HttpEntity<>(headers), Map.class).getBody();
            if (root == null || !(root.get("location") instanceof Map<?, ?> location)) {
                return Optional.empty();
            }

            if (!(location.get("latitude") instanceof Number lat) || !(location.get("longitude") instanceof Number lng)) {
                return Optional.empty();
            }

            String suburb = firstComponent(root,
                    "sublocality_level_1",
                    "sublocality",
                    "neighborhood",
                    "sublocality_level_2");

            String city = firstComponent(root,
                    "locality",
                    "postal_town",
                    "administrative_area_level_2");

            if (suburb.isBlank()) {
                suburb = city;
            }

            if (city.isBlank()) {
                city = suburb;
            }

            return Optional.of(new PlaceLocation(
                    lat.doubleValue(),
                    lng.doubleValue(),
                    asText(root.get("formattedAddress")),
                    suburb,
                    city));
        } catch (RestClientException e) {
            log.warn("Place details lookup failed: {}", e.getClass().getSimpleName());
            return Optional.empty();
        }
    }

    private static String asText(Object value) {
        return value == null ? "" : value.toString();
    }

    private static String firstComponent(Map<?, ?> root, String... wantedTypes) {
        if (!(root.get("addressComponents") instanceof List<?> components)) {
            return "";
        }

        for (String wanted : wantedTypes) {
            for (Object component : components) {
                if (!(component instanceof Map<?, ?> map)) {
                    continue;
                }

                if (!(map.get("types") instanceof List<?> types) || !types.contains(wanted)) {
                    continue;
                }

                String longText = asText(map.get("longText")).trim();
                if (!longText.isEmpty()) {
                    return longText;
                }

                String shortText = asText(map.get("shortText")).trim();
                if (!shortText.isEmpty()) {
                    return shortText;
                }
            }
        }
        return "";
    }

    private static boolean isValidSessionToken(String token) {
        return token != null && SESSION_TOKEN.matcher(token).matches();
    }
}