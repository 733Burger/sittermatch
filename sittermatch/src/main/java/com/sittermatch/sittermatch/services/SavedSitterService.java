package com.sittermatch.sittermatch.services;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.sittermatch.sittermatch.dto.savedSitterDetails.SavedSitterListResponse;
import com.sittermatch.sittermatch.dto.savedSitterDetails.ToggleSavedSitterResponse;
import com.sittermatch.sittermatch.model.SavedSitter;
import com.sittermatch.sittermatch.model.Sitter;
import com.sittermatch.sittermatch.repository.SavedSitterRepository;
import com.sittermatch.sittermatch.repository.SitterRepository;

import jakarta.transaction.Transactional;

@Service 
public class SavedSitterService {
  
    private final SavedSitterRepository savedSitterRepository;
    private final SitterRepository sitterRepository;

    public SavedSitterService(SavedSitterRepository savedSitterRepository, SitterRepository sitterRepository) {
        this.savedSitterRepository = savedSitterRepository;
        this.sitterRepository = sitterRepository;
    }

    public List<SavedSitterListResponse> getSavedSitters(int homeownerId) {
        if (homeownerId <= 0) {
            return List.of();
        }

        Set<Integer> savedSitterIds = savedSitterRepository
                                    .findByHomeownerId(homeownerId)
                                    .stream()
                                    .map(savedSitter -> savedSitter.getSitterId())
                                    .collect(Collectors.toSet());

        if (savedSitterIds.isEmpty()) {
            return List.of();
        }

        return sitterRepository.findAllById(savedSitterIds)
                .stream()
                .map(sitter -> toSavedSitterListResponse(sitter))
                .toList();
    }

    private SavedSitterListResponse toSavedSitterListResponse (Sitter sitter) {
        var sitterUserDetails = sitter.getUser();
        return new SavedSitterListResponse(
            sitter.getId(),
            (sitterUserDetails != null) ? sitterUserDetails.getName() : null,
            sitter.getRating(),
            sitter.getTotalReviews(),
            sitter.getDayRate(),
            sitter.getNightRate(),
            sitter.getIsVerified()
        );
    }

    @Transactional 
    public ToggleSavedSitterResponse toggleSitter( Integer homeownerId, Integer sitterId, Boolean isCurrentlySaved) {
        if (homeownerId == null || sitterId == null || homeownerId <= 0 || sitterId <= 0) {
            return ToggleSavedSitterResponse.failure("homeownerId and sitterId are required.");
        }

        if (isCurrentlySaved == null) {
            return ToggleSavedSitterResponse.failure("isCurrentlySaved is required.");
        }

        if (isCurrentlySaved) {
            return removeSitter(homeownerId, sitterId);
        } else {
            return addSitter(homeownerId, sitterId);
        }
    }

    private ToggleSavedSitterResponse removeSitter(Integer homeownerId, Integer sitterId) {
        savedSitterRepository.deleteByHomeownerIdAndSitterId(homeownerId, sitterId);
        
        return ToggleSavedSitterResponse.removed();
    }

    private ToggleSavedSitterResponse addSitter(Integer homeownerId, Integer sitterId) {
        boolean alreadySaved = savedSitterRepository.findByHomeownerIdAndSitterId(homeownerId, sitterId).isPresent();
        if (!alreadySaved) {
            savedSitterRepository.save(new SavedSitter(homeownerId, sitterId));
        }

        return ToggleSavedSitterResponse.saved();
    }
}
