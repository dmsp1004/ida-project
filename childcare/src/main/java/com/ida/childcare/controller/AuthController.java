package com.ida.childcare.controller;

import com.ida.childcare.dto.AuthResponse;
import com.ida.childcare.dto.LoginRequest;
import com.ida.childcare.dto.RegisterRequest;
import com.ida.childcare.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.ok(userService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        System.out.println("로그인 요청: " + request.getEmail());
        try {
            AuthResponse response = userService.login(request);
            System.out.println("로그인 성공: " + request.getEmail());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.out.println("로그인 실패: " + e.getMessage());
            throw e;
        }
    }
}