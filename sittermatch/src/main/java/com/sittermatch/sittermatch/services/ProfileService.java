package com.sittermatch.sittermatch.services;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.sittermatch.sittermatch.dto.ProfileResponse;
import com.sittermatch.sittermatch.dto.SitterProfileResponse;
import com.sittermatch.sittermatch.dto.SitterProfileUpdateRequest;
import com.sittermatch.sittermatch.dto.UpdateProfileRequest;
import com.sittermatch.sittermatch.dto.profile.PetUpdateResult;
import com.sittermatch.sittermatch.dto.profile.ServiceUpdateResult;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.model.SitterServices;
import com.sittermatch.sittermatch.model.User;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;
import com.sittermatch.sittermatch.repository.UserRepository;

import jakarta.transaction.Transactional;

@Service
public class ProfileService {
    private final PlacesService placesService;
    private final HomeownerRepository homeownerRepository;
    private final SitterRepository sitterRepository;
    private final UserRepository userRepository;

    private static final Set<String> ALLOWED_SERVICES = Set.of("STAY_OVER_NIGHT", "WALK_PET", "FEED_PET");
    private static final Set<String> ALLOWED_PETS = Set.of("LARGE DOG", "SMALL DOG", "CAT", "BIRD", "REPTILE",
            "FISH", "EXOTIC");

    public ProfileService(PlacesService placesService,
                        HomeownerRepository homeownerRepository,
                        SitterRepository sitterRepository,
                        UserRepository userRepository) {
        this.placesService = placesService;
        this.homeownerRepository = homeownerRepository;
        this.sitterRepository = sitterRepository;
        this.userRepository = userRepository;
    }

    // Homeowner profile

    public ProfileResponse getProfile(Integer userId) {
        Optional<Homeowner> found = homeownerRepository.findById(userId);
        if (found.isEmpty()) {
            return ProfileResponse.failure("Homeowner not found");
        }
        return toProfileResponse(found.get(), "Profile loaded");
    }

    @Transactional
    public ProfileResponse updateProfile(Integer userId, UpdateProfileRequest req) {
        Optional<Homeowner> foundHomeowner = homeownerRepository.findById(userId);
        if (foundHomeowner.isEmpty()) {
            return ProfileResponse.failure("Homeowner not found");
        }

        String name = req.name() == null ? "" : req.name().trim();
        String email = req.email() == null ? "" : req.email().trim().toLowerCase();
        String phone = req.phone() == null ? "" : req.phone().trim();
        String address = req.address() == null ? "" : req.address().trim();
        String requirements = req.requirements() == null ? "" : req.requirements().trim();

        if (name.isBlank() || name.length() > 100) {
            return ProfileResponse.failure("Enter a name under 100 characters.");
        }

        if (email.isBlank() || email.length() > 255 || !email.contains("@")) {
            return ProfileResponse.failure("Enter a valid email address.");
        }

        if (phone.length() > 20 || (!phone.isEmpty() && !phone.matches("[0-9+()\\- ]+"))) {
            return ProfileResponse.failure("Enter a phone number under 20 characters.");
        }

        if (address.isBlank() || address.length() > 255) {
            return ProfileResponse.failure("Enter an address under 255 characters.");
        }

        if (requirements.isBlank() || requirements.length() > 255) {
            return ProfileResponse.failure("Requirements must be 1-255 characters.");
        }

        Optional<User> emailOwner = userRepository.findByEmailIgnoreCase(email);
        if (emailOwner.isPresent() && !emailOwner.get().getId().equals(userId)) {
            return ProfileResponse.failure("That email is already in use.");
        }

        Homeowner homeowner = foundHomeowner.get();
        String storedAddress = emptyIfNull(homeowner.getAddress());
        boolean sameAddress = address.equals(storedAddress);
        String placeId = req.placeId() == null ? "" : req.placeId().trim();

        if (!placeId.isEmpty()) {
            Optional<PlacesService.PlaceLocation> location = placesService.getLocation(placeId, req.sessionToken());

            if (location.isEmpty()) {
                return ProfileResponse.failure(
                        "Could not confirm that address. Select it again from the suggestions.");
            }

            String formatted = location.get().formattedAddress() == null
                    ? ""
                    : location.get().formattedAddress().trim();

            if (!formatted.isBlank()) {
                address = formatted;
            }

            if (address.length() > 255) {
                return ProfileResponse.failure("That address is too long to save.");
            }

            String suburb = location.get().suburb() == null ? "" : location.get().suburb().trim();
            String city = location.get().city() == null ? "" : location.get().city().trim();

            if (suburb.isBlank()) {
                return ProfileResponse.failure("Select an address that includes a suburb.");
            }

            if (suburb.length() > 100 || city.length() > 100) {
                return ProfileResponse.failure("That suburb or city name is too long to save.");
            }

            homeowner.setLatitude(coordinate(location.get().latitude()));
            homeowner.setLongitude(coordinate(location.get().longitude()));
            homeowner.setSuburb(suburb);
            homeowner.setCity(city);
        } else if (!sameAddress) {
            return ProfileResponse.failure("Select your home address from the suggestions.");
        }

        User user = homeowner.getUser();
        user.setName(name);
        user.setEmail(email);
        user.setPhone(phone);
        homeowner.setAddress(address);
        homeowner.setRequirements(requirements);

        userRepository.save(user);
        homeownerRepository.save(homeowner);

        return toProfileResponse(homeowner, "Profile updated");
    }

    private ProfileResponse toProfileResponse(Homeowner h, String message) {
        User u = h.getUser();
        return new ProfileResponse(true, message, u.getName(), u.getEmail(), u.getPhone(),
                emptyIfNull(h.getAddress()), emptyIfNull(h.getRequirements()),
                toDouble(h.getLatitude()), toDouble(h.getLongitude()),
                emptyIfNull(h.getSuburb()), emptyIfNull(h.getCity()));
    }

    // Sitter profile

    @Transactional
    public SitterProfileResponse getSitterProfile(Integer userId) {
        Optional<Sitter> found = sitterRepository.findById(userId);
        if (found.isEmpty()) {
            return SitterProfileResponse.failure("Sitter not found");
        }
        return toSitterProfileResponse(found.get(), "Profile loaded");
    }

    // Each profile card sends only its own section; a null section is left unchanged.
    @Transactional
    public SitterProfileResponse updateSitterProfile(Integer userId, SitterProfileUpdateRequest req) {
        Optional<Sitter> found = sitterRepository.findById(userId);
        if (found.isEmpty()) {
            return SitterProfileResponse.failure("Sitter not found");
        }
        Sitter sitter = found.get();
        User user = sitter.getUser();

        String userError = validateAndUpdateUser(user, req, userId);
        if (userError != null) {
            return SitterProfileResponse.failure(userError);
        }

        String expError = validateAndUpdateExperience(sitter, req);
        if (expError != null) {
            return SitterProfileResponse.failure(expError);
        }

        ServiceUpdateResult serviceResult = validateAndMapServices(req);
        if (serviceResult.error() != null) {
            return SitterProfileResponse.failure(serviceResult.error());
        }

        PetUpdateResult petResult = validateAndMapPets(req);
        if (petResult.error() != null) {
            return SitterProfileResponse.failure(petResult.error());
        }

        String locationError = validateAndUpdateLocation(sitter, req);
        if (locationError != null) {
            return SitterProfileResponse.failure(locationError);
        }

        applyServiceAndPetUpdates(sitter, serviceResult, petResult);

        userRepository.save(user);
        sitterRepository.save(sitter);

        return toSitterProfileResponse(sitter, "Profile updated");
    }

    private String validateAndUpdateUser(User user, SitterProfileUpdateRequest req, Integer userId) {
        boolean updateUser = req.name() != null || req.email() != null || req.phone() != null;
        if (!updateUser) return null;

        String name = req.name() == null ? "" : req.name().trim();
        String email = req.email() == null ? "" : req.email().trim().toLowerCase();
        String phone = req.phone() == null ? "" : req.phone().trim();

        if (name.isBlank() || name.length() > 100) {
            return "Enter a name under 100 characters.";
        }

        if (email.isBlank() || email.length() > 255 || !email.contains("@")) {
            return "Enter a valid email address.";
        }

        if (phone.length() > 20 || (!phone.isEmpty() && !phone.matches("[0-9+()\\-\\s]+"))) {
            return "Enter a phone number under 20 characters.";
        }

        Optional<User> emailOwner = userRepository.findByEmailIgnoreCase(email);
        if (emailOwner.isPresent() && !emailOwner.get().getId().equals(userId)) {
            return "That email is already in use.";
        }

        user.setName(name);
        user.setEmail(email);
        user.setPhone(phone);
        return null;
    }

    private String validateAndUpdateExperience(Sitter sitter, SitterProfileUpdateRequest req) {
        String experience = req.experience() == null ? null : req.experience().trim();
        if (experience != null) {
            if (experience.length() > 2000) {
                return "About & experience must be under 2000 characters.";
            }

            sitter.setExperience(experience);
        }

        return null;
    }

    private ServiceUpdateResult validateAndMapServices(SitterProfileUpdateRequest req) {
        if (req.services() == null) return new ServiceUpdateResult(null, null, null);
        if (req.services().isEmpty()) return new ServiceUpdateResult(null, null, "Select at least one service.");

        Set<SitterServices> newServices = new HashSet<>();
        Double nightRate = null;

        for (var s : req.services()) {
            String type = s.serviceType() == null ? "" : s.serviceType().trim().toUpperCase();
            if (!ALLOWED_SERVICES.contains(type)) {
                return new ServiceUpdateResult(null, null, "Unknown service type.");
            }

            if (s.price() == null || s.price() <= 0 || s.price() > 1_000_000) {
                return new ServiceUpdateResult(null, null, "Enter a valid price for every selected service.");
            }

            Integer duration = null;
            if (type.equals("WALK_PET")) {
                if (s.durationMinutes() == null || s.durationMinutes() <= 0) {
                    return new ServiceUpdateResult(null, null, "Enter the walk length in minutes.");
                }

                duration = s.durationMinutes();
            }

            BigDecimal price = BigDecimal.valueOf(s.price()).setScale(2, RoundingMode.HALF_UP);
            if (type.equals("STAY_OVER_NIGHT")) {
                nightRate = price.doubleValue();
            }

            newServices.add(new SitterServices(type, price, duration));
        }

        return new ServiceUpdateResult(newServices, nightRate, null);
    }

    private PetUpdateResult validateAndMapPets(SitterProfileUpdateRequest req) {
        if (req.petPreferences() == null) return new PetUpdateResult(null, null);

        Set<String> newPets = new HashSet<>();
        for (String p : req.petPreferences()) {
            String v = p == null ? "" : p.trim().toUpperCase();
            if (!ALLOWED_PETS.contains(v)) {
                return new PetUpdateResult(null, "Unknown pet type.");
            }

            newPets.add(v);
        }

        if (newPets.isEmpty()) {
            return new PetUpdateResult(null, "Select at least one pet type.");
        }

        return new PetUpdateResult(newPets, null);
    }

    private String validateAndUpdateLocation(Sitter sitter, SitterProfileUpdateRequest req) {
        if (req.serviceArea() == null) return null;

        String serviceArea = req.serviceArea().trim();
        if (serviceArea.length() > 255) {
            return "That area name is too long to save.";
        }

        String storedArea = serviceAreaText(sitter);

        String placeId = req.placeId() == null ? "" : req.placeId().trim();
        if (!placeId.isEmpty()) {
            Optional<PlacesService.PlaceLocation> location = placesService.getLocation(placeId, req.sessionToken());
            if (location.isEmpty()) {
                return "Could not confirm that area. Select it again from the suggestions.";
            }

            PlacesService.PlaceLocation place = location.get();
            String formatted = place.formattedAddress() == null ? "" : place.formattedAddress().trim();
            if (!formatted.isBlank()) {
                serviceArea = formatted;
            }

            if (serviceArea.length() > 255) {
                return "That area name is too long to save.";
            }

            String suburb = place.suburb() == null ? "" : place.suburb().trim();
            String city = place.city() == null ? "" : place.city().trim();
            if (suburb.isBlank()) {
                return "Select an area that includes a suburb.";
            }

            if (suburb.length() > 100 || city.length() > 100) {
                return "That suburb or city name is too long to save.";
            }

            sitter.setServiceArea(serviceArea);
            sitter.setLatitude(coordinate(place.latitude()));
            sitter.setLongitude(coordinate(place.longitude()));
            sitter.setSuburb(suburb);
            sitter.setCity(city);
        } else if (!serviceArea.equals(storedArea)
                || sitter.getLatitude() == null
                || sitter.getLongitude() == null
                || blankToEmpty(sitter.getSuburb()).isBlank()) {
            return "Select the area you work in from the suggestions.";
        }

        return null;
    }

    private void applyServiceAndPetUpdates(Sitter sitter, ServiceUpdateResult serviceResult, PetUpdateResult petResult) {
        if (serviceResult.services() != null || petResult.pets() != null) {
            if (serviceResult.services() != null) {
                sitter.setNightRate(serviceResult.nightRate());
                sitter.getServices().clear();
            }

            if (petResult.pets() != null) {
                sitter.getPetPreferences().clear();
            }

            sitterRepository.saveAndFlush(sitter);

            if (serviceResult.services() != null) {
                sitter.getServices().addAll(serviceResult.services());
            }

            if (petResult.pets() != null) {
                sitter.getPetPreferences().addAll(petResult.pets());
            }
        }
    }

    private SitterProfileResponse toSitterProfileResponse(Sitter s, String message) {
        User u = s.getUser();
        return new SitterProfileResponse(true, message, u.getName(), u.getEmail(), u.getPhone(),
                emptyIfNull(s.getExperience()), s.getRating(), s.getTotalReviews(),
                serviceAreaText(s), blankToEmpty(s.getSuburb()), blankToEmpty(s.getCity()),
                toDouble(s.getLatitude()), toDouble(s.getLongitude()),
                s.getPetPreferences().stream().toList(),
                s.getServices().stream()
                        .map(service -> new SitterProfileResponse.ServiceItem(service.getServiceType(),
                                toDouble(service.getPrice()), service.getDurationMinutes()))
                        .toList());
    }

    // Older sitters only have a suburb stored, so fall back to it as the area text.
    private static String serviceAreaText(Sitter sitter) {
        String area = blankToEmpty(sitter.getServiceArea());
        return area.isBlank() ? blankToEmpty(sitter.getSuburb()) : area;
    }

    // Shared helpers

    private static BigDecimal coordinate(double value) {
        return BigDecimal.valueOf(value).setScale(6, RoundingMode.HALF_UP);
    }

    private static Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }

    private static String emptyIfNull(String string) {
        return (string == null) ? "" : string;
    }

    private static String blankToEmpty(String value) {
        return value == null ? "" : value.trim();
    }
}
