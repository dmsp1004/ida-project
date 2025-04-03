package com.ida.childcare.controller;

import com.ida.childcare.dto.AuthResponse;
import com.ida.childcare.dto.OAuthRegisterRequest;
import com.ida.childcare.entity.Parent;
import com.ida.childcare.entity.Sitter;
import com.ida.childcare.entity.User;
import com.ida.childcare.repository.UserRepository;
import com.ida.childcare.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
public class OAuthRegisterController {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    @Autowired
    public OAuthRegisterController(UserRepository userRepository, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping("/oauth/register")
    public ResponseEntity<AuthResponse> registerByOAuth(@RequestBody OAuthRegisterRequest request) {

        Optional<User> existing = userRepository.findByEmail(request.getEmail());
        if (existing.isPresent()) {
            throw new IllegalArgumentException("이미 등록된 이메일입니다.");
        }

        User user;
        if ("PARENT".equalsIgnoreCase(request.getUserType())) {
            Parent parent = new Parent();
            parent.setNumberOfChildren(request.getNumberOfChildren());
            parent.setAddress(request.getAddress());
            parent.setAdditionalInfo(request.getAdditionalInfo());
            user = parent;
        } else {
            Sitter sitter = new Sitter();
            sitter.setSitterType(Sitter.SitterType.valueOf(request.getSitterType()));
            sitter.setExperienceYears(request.getExperienceYears());
            sitter.setHourlyRate(request.getHourlyRate());
            sitter.setBio(request.getBio());
            user = sitter;
        }

        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setProvider(request.getProvider());
        user.setProviderId(request.getProviderId());
        user.setPassword("OAUTH2_" + UUID.randomUUID());

        User savedUser = userRepository.save(user);

        UserDetails userDetails = new org.springframework.security.core.userdetails.User(
                savedUser.getEmail(), savedUser.getPassword(), new ArrayList<>());

        String token = jwtUtil.generateToken(userDetails);

        return ResponseEntity.ok(new AuthResponse(token, savedUser.getId(), savedUser.getEmail(), savedUser.getUserType().toString()));
    }
}
