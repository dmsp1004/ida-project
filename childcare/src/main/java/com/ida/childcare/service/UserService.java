package com.ida.childcare.service;

import com.ida.childcare.dto.AuthResponse;
import com.ida.childcare.dto.LoginRequest;
import com.ida.childcare.dto.RegisterRequest;
import com.ida.childcare.entity.Admin;
import com.ida.childcare.entity.Parent;
import com.ida.childcare.entity.Sitter;
import com.ida.childcare.entity.User;
import com.ida.childcare.repository.UserRepository;
import com.ida.childcare.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.lang.reflect.Field;
import java.util.ArrayList;

@Service
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Autowired
    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                new ArrayList<>()
        );
    }

    public AuthResponse register(RegisterRequest request) {
        // 이메일 중복 확인
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("이미 등록된 이메일입니다");
        }

        // 회원 유형에 따라 엔티티 생성
        User user;
        User.UserType userType;

        if (request.getUserType().equals("PARENT")) {
            user = new Parent();
            userType = User.UserType.PARENT;
        } else if (request.getUserType().equals("SITTER")) {
            user = new Sitter();
            userType = User.UserType.SITTER;
        } else if (request.getUserType().equals("ADMIN")) {
            user = new Admin();
            userType = User.UserType.ADMIN;
        } else {
            throw new RuntimeException("잘못된 회원 유형입니다");
        }

        // 사용자 정보 설정
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setPhoneNumber(request.getPhoneNumber());

        // 수동으로 userType 값 설정 (리플렉션 사용)
        try {
            Field userTypeField = User.class.getDeclaredField("userType");
            userTypeField.setAccessible(true);
            userTypeField.set(user, userType);
        } catch (Exception e) {
            throw new RuntimeException("사용자 유형 설정 실패", e);
        }

        // 저장
        user = userRepository.save(user);

        // JWT 토큰 생성
        UserDetails userDetails = loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getUserType() != null ? user.getUserType().toString() : request.getUserType())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        // 직접 인증 처리
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + request.getEmail()));

        // 비밀번호 검증
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid password");
        }

        // JWT 토큰 생성
        UserDetails userDetails = loadUserByUsername(user.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return new AuthResponse(
                token,
                user.getId(),
                user.getEmail(),
                user.getUserType().toString()
        );
    }

    // Admin 계정 생성을 위한 메서드
    public AuthResponse createAdminAccount(String email, String password, String phoneNumber) {
        // 이메일 중복 확인
        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("이미 등록된 이메일입니다");
        }

        // Admin 엔티티 생성
        Admin admin = new Admin();
        admin.setEmail(email);
        admin.setPassword(passwordEncoder.encode(password));
        admin.setPhoneNumber(phoneNumber);
        admin.setDepartment("System");
        admin.setAdminLevel(1);
        admin.setAccessAllRecords(true);

        // 저장
        admin = userRepository.save(admin);

        // JWT 토큰 생성
        UserDetails userDetails = loadUserByUsername(admin.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .userId(admin.getId())
                .email(admin.getEmail())
                .role(admin.getUserType().toString())
                .build();
    }
}