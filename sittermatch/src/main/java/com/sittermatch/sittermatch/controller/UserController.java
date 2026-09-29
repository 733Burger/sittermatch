package com.sittermatch.sittermatch.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sittermatch.sittermatch.dto.RoleActionRequest;
import com.sittermatch.sittermatch.dto.RoleActionResponse;
import com.sittermatch.sittermatch.dto.UserRoleResponse;
import com.sittermatch.sittermatch.services.UserService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PostMapping;



@RestController 
@RequestMapping("/api/users")
public class UserController {
    
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping ("/{email}/roles")
    public ResponseEntity<UserRoleResponse> getUserRoles(@PathVariable String email) {
        UserRoleResponse response = userService.getUserRoles(email);
        if (!response.success()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PatchMapping ("/{email}/role-switch")
    public ResponseEntity<RoleActionResponse> switchActiveRole(@PathVariable String email, @RequestBody RoleActionRequest request) {
        RoleActionResponse response = userService.switchActiveRole(email, request.role());
        if (!response.success()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/{email}/roles")
    public ResponseEntity<RoleActionResponse> addRole(@PathVariable String email, @RequestBody RoleActionRequest request) {
        RoleActionResponse response = userService.addRole(email, request.role());
        if (!response.success()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
        return ResponseEntity.ok(response);
    }
    
}
