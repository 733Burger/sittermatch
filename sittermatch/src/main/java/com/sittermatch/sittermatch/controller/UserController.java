package com.sittermatch.sittermatch.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sittermatch.sittermatch.dto.UserRoleResponse;
import com.sittermatch.sittermatch.services.UserService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;


@RestController 
@RequestMapping("/api/users")
public class UserController {
    
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping ("/{email}/roles")
    public ResponseEntity<UserRoleResponse> getUserRoles(@PathVariable String email) {
        UserRoleResponse roles = userService.getUserRoles(email);
        if (!roles.success()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(roles);
        }
        return ResponseEntity.ok(roles);
    }
    
}
