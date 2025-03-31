package com.ida.childcare.controller;

import com.ida.childcare.dto.AuthResponse;
import com.ida.childcare.dto.LoginRequest;
import com.ida.childcare.dto.RegisterRequest;
import com.ida.childcare.entity.User;
import com.ida.childcare.repository.UserRepository;
import com.ida.childcare.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserService userService;
    @Autowired
    private UserRepository userRepository;

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

    @GetMapping("/validate-token")
    public ResponseEntity<?> validateToken() {

        // SecurityContext에서 현재 인증된 사용자 정보 가져오기
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null && authentication.isAuthenticated() &&
                !(authentication instanceof AnonymousAuthenticationToken)) {
            String email = authentication.getName();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

            return ResponseEntity.ok(Map.of(
                    "valid", true,
                    "email", email,
                    "userId", user.getId(),
                    "role", user.getUserType().toString()
            ));
        }

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("valid", false));
    }
}