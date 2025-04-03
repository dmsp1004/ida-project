package com.ida.childcare.service;

import com.ida.childcare.dto.AuthResponse;
import com.ida.childcare.dto.LoginRequest;
import com.ida.childcare.dto.OAuthRegisterRequest;
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
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional
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
    @Transactional
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

    /**
     * 소셜 로그인 사용자의 회원가입 완료 메서드
     */
    @Transactional
    public AuthResponse completeOAuthRegistration(OAuthRegisterRequest request) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new UsernameNotFoundException("소셜 인증 정보가 없습니다. 이메일: " + request.getEmail()));

        // 소셜 로그인 정보 검증
        if (user.getProvider() == null || !user.getProvider().equals(request.getProvider())) {
            throw new RuntimeException("소셜 로그인 정보가 일치하지 않습니다");
        }

        // 사용자 유형 변경 (PARENT/SITTER)
        User.UserType userType;

        if (request.getUserType().equals("PARENT")) {
            // 기존 사용자가 Parent가 아니면 새로 생성
            if (!(user instanceof Parent)) {
                Parent parent = new Parent();
                copyBaseUserProperties(user, parent);
                updateParentInfo(parent, request);
                user = parent;
            } else {
                // 이미 Parent인 경우 정보 업데이트
                updateParentInfo((Parent) user, request);
            }
            userType = User.UserType.PARENT;
        } else if (request.getUserType().equals("SITTER")) {
            // 기존 사용자가 Sitter가 아니면 새로 생성
            if (!(user instanceof Sitter)) {
                Sitter sitter = new Sitter();
                copyBaseUserProperties(user, sitter);
                updateSitterInfo(sitter, request);
                user = sitter;
            } else {
                // 이미 Sitter인 경우 정보 업데이트
                updateSitterInfo((Sitter) user, request);
            }
            userType = User.UserType.SITTER;
        } else {
            throw new RuntimeException("잘못된 회원 유형입니다");
        }

        // 전화번호 업데이트
        user.setPhoneNumber(request.getPhoneNumber());

        // userType 설정 (리플렉션 사용)
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

    /**
     * 기본 사용자 속성 복사 메서드
     */
    private void copyBaseUserProperties(User source, User target) {
        target.setId(source.getId());
        target.setEmail(source.getEmail());
        target.setPassword(source.getPassword());
        target.setProvider(source.getProvider());
        target.setProviderId(source.getProviderId());
    }

    /**
     * Parent 정보 업데이트 메서드
     */
    private void updateParentInfo(Parent parent, OAuthRegisterRequest request) {
        if (request.getNumberOfChildren() != null) {
            parent.setNumberOfChildren(request.getNumberOfChildren());
        }
        if (request.getAddress() != null) {
            parent.setAddress(request.getAddress());
        }
        if (request.getAdditionalInfo() != null) {
            parent.setAdditionalInfo(request.getAdditionalInfo());
        }
    }

    /**
     * Sitter 정보 업데이트 메서드
     */
    private void updateSitterInfo(Sitter sitter, OAuthRegisterRequest request) {
        if (request.getSitterType() != null) {
            try {
                Sitter.SitterType sitterType = Sitter.SitterType.valueOf(request.getSitterType());
                sitter.setSitterType(sitterType);
            } catch (IllegalArgumentException e) {
                // 유효하지 않은 SitterType 값이면 무시
            }
        }
        if (request.getExperienceYears() != null) {
            sitter.setExperienceYears(request.getExperienceYears());
        }
        if (request.getHourlyRate() != null) {
            sitter.setHourlyRate(request.getHourlyRate());
        }
        if (request.getBio() != null) {
            sitter.setBio(request.getBio());
        }

        // 기본 검증 상태 설정
        sitter.setIsVerified(false);
        sitter.setBackgroundCheckCompleted(false);
        sitter.setInterviewCompleted(false);
    }
}