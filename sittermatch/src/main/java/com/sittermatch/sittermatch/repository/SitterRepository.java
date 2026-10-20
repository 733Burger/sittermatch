package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.dto.sitterDetails.SitterDetailsResponse.ServiceProjection;
import com.sittermatch.sittermatch.dto.sitterDetails.SitterDetailsResponse.SitterDetailsProjection;
import com.sittermatch.sittermatch.model.Sitter;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
 
public interface SitterRepository extends JpaRepository<Sitter, Integer> {

    // Find sitter by underlying User's email
    Optional<Sitter> findByUserEmail(String email);

    // // Find sitters who are verified
    // List<Sitter> findByIsVerifiedTrue();

    // // Find sitters offering a specific service string
    // // List<Sitter> findByServiceTypesContaining(String serviceType);

    // // Find sitters accommodating a specific pet type string
    // List<Sitter> findByPetTypesContaining(String petType);

    // // Find sitters within a maximum day rate limit
    // List<Sitter> findByDayRateLessThanEqual(Double maxDayRate);

    @Query(
        value = "SELECT u.name AS name,"
            + " u.email AS email,"
            + " u.phone AS phone,"
            + " s.experience AS experience,"
            + " s.day_rate AS dayRate,"
            + " s.night_rate AS nightRate,"
            + " s.rating AS rating,"
            + " s.total_reviews AS totalReview,"
            + " s.is_verified AS isVerified"
            + " FROM users u"
            + " JOIN sitters s ON u.id = s.id"
            + " WHERE u.id = :sitterId",
        nativeQuery = true
    )
    SitterDetailsProjection getSitterDetails(@Param("sitterId") Integer sitterId);

    @Query(
        value = "SELECT pet_type"
            + " FROM sitter_pet_preferences "
            + " WHERE sitter_id = :sitterId",
        nativeQuery = true
    )
    List<String> findPetPreferences(@Param("sitterId") Integer sitterId);

    @Query(
        value = "SELECT service_type AS serviceType,"
            + " price AS price,"
            + " duration_minutes AS durationMinutes"
            + " FROM sitter_services"
            + " WHERE sitter_id = :sitterId"
            + " ORDER BY service_type",
        nativeQuery = true
    )
    List<ServiceProjection> findSitterServices(@Param("sitterId") Integer sitterId);
}
