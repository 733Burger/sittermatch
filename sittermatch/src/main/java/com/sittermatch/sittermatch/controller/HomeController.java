package com.sittermatch.sittermatch.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.sittermatch.sittermatch.dto.HomeownerCheckResponse;
import com.sittermatch.sittermatch.services.HomeService;

@RestController 
@RequestMapping("/api/home")
@CrossOrigin (origins = "*")
public class HomeController {
    private final HomeService homeService;

    public HomeController(HomeService homeService) {
        this.homeService = homeService;
    }

    @GetMapping("/{email..+}/checks")
    public ResponseEntity<HomeownerCheckResponse> getVerificarion(@PathVariable String email) {
        HomeownerCheckResponse response = homeService.getVerification(email);
        return ResponseEntity.ok(response);
    }
}
