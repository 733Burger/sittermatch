package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.services.PlacesService;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/places")
@CrossOrigin(origins = "*")
public class PlacesController {

    private final PlacesService placesService;

    public PlacesController(PlacesService placesService) {
        this.placesService = placesService;
    }

    @GetMapping("/autocomplete")
    public List<PlacesService.Suggestion> autocomplete(
            @RequestParam String input,
            @RequestParam(required = false) String sessionToken) {
        return placesService.autocomplete(input, sessionToken);
    }
}