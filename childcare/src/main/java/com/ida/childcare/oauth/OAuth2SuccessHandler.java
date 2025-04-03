package com.ida.childcare.oauth;

import com.ida.childcare.entity.User;
import com.ida.childcare.repository.UserRepository;
import com.ida.childcare.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import java.util.Optional;

@Component
public class OAuth2SuccessHandler implements AuthenticationSuccessHandler {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    @Autowired
    public OAuth2SuccessHandler(UserRepository userRepository, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
    }

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
                                        Authentication authentication) throws IOException {

        OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
        Map<String, Object> attributes = oAuth2User.getAttributes();

        String email = extractEmail(attributes, getProvider(request));

        if (email == null || email.isBlank()) {
            // 이메일을 가져올 수 없는 경우 처리
            response.sendRedirect("/oauth2/error?reason=email_not_found");
            return;
        }

        // 요청 파라미터에서 모드(로그인 또는 회원가입) 확인
        String mode = request.getParameter("mode");
        boolean isSignupMode = "signup".equalsIgnoreCase(mode);

        Optional<User> userOptional = userRepository.findByEmail(email);
        boolean isNewUser = !userOptional.isPresent();
        String redirectUrl;

        // 사용자가 이미 존재하는 경우
        if (userOptional.isPresent()) {
            User user = userOptional.get();

            // 회원가입 모드인데 이미 계정이 있는 경우
            if (isSignupMode) {
                redirectUrl = "/oauth-test.html?error=already_registered&email=" + email;
            }
            // 로그인 모드이고 사용자 정보가 완전한 경우 (바로 로그인)
            else if (user.getUserType() != null && isProfileComplete(user)) {
                // JWT 토큰 생성
                UserDetails userDetails = new org.springframework.security.core.userdetails.User(
                        user.getEmail(), user.getPassword(), new java.util.ArrayList<>());
                String token = jwtUtil.generateToken(userDetails);

                // 로그인 성공 페이지로 리다이렉트 (토큰 포함)
                redirectUrl = UriComponentsBuilder.fromUriString("/oauth-test.html")
                        .queryParam("token", token)
                        .queryParam("email", email)
                        .queryParam("userId", user.getId())
                        .queryParam("role", user.getUserType().toString())
                        .build().toUriString();
            }
            // 로그인 모드이지만 사용자 정보가 불완전한 경우 (추가 정보 입력 필요)
            else {
                redirectUrl = "/oauth-test.html?isNewUser=false";
            }
        }
        // 새 사용자인 경우
        else {
            // 처음 소셜 로그인하는 사용자는 회원가입 처리
            redirectUrl = "/oauth-test.html?isNewUser=true";
        }

        // 소셜 로그인 정보를 세션에 저장하는 API 호출 후 적절한 페이지로 리다이렉트
        String provider = getProvider(request);  // ← 먼저 선언
        String providerId = extractProviderId(attributes, provider);

        String targetUrl = UriComponentsBuilder.fromUriString("/api/public/oauth/store-session")
                .queryParam("email", email)
                .queryParam("provider", provider)
                .queryParam("providerId", providerId)  // ← 이 부분이 핵심입니다
                .queryParam("redirectUrl", redirectUrl)
                .queryParam("mode", isSignupMode ? "signup" : "login")
                .build().toUriString();

        response.sendRedirect(targetUrl);
    }

    // 사용자 프로필이 완성되었는지 확인
    private boolean isProfileComplete(User user) {
        return user.getPhoneNumber() != null && !user.getPhoneNumber().isEmpty();
    }

    // OAuth 제공자별 이메일 추출 로직
    private String extractEmail(Map<String, Object> attributes, String provider) {
        if ("google".equals(provider)) {
            return (String) attributes.get("email");
        } else if ("kakao".equals(provider)) {
            Map<String, Object> kakaoAccount = (Map<String, Object>) attributes.get("kakao_account");
            if (kakaoAccount != null && kakaoAccount.containsKey("email")) {
                return (String) kakaoAccount.get("email");
            }
        } else if ("naver".equals(provider)) {
            // 직접 접근 방식 먼저 시도
            if (attributes.containsKey("email")) {
                return (String) attributes.get("email");
            }

            // 중첩된 방식 시도
            Map<String, Object> response = (Map<String, Object>) attributes.get("response");
            if (response != null && response.containsKey("email")) {
                return (String) response.get("email");
            }
        }
        return null;
    }

    // OAuth 제공자 정보 추출
    private String getProvider(HttpServletRequest request) {
        String requestURI = request.getRequestURI();
        if (requestURI.contains("/google")) {
            return "google";
        } else if (requestURI.contains("/kakao")) {
            return "kakao";
        } else if (requestURI.contains("/naver")) {
            return "naver";
        }
        return "unknown";
    }

    //소셜 로그인 사용자 고유 식별자(providerId)를 OAuth2 응답 속성에서 추출.
    private String extractProviderId(Map<String, Object> attributes, String provider) {
        if ("google".equals(provider)) {
            return (String) attributes.get("sub");
        } else if ("kakao".equals(provider)) {
            return String.valueOf(attributes.get("id"));
        } else if ("naver".equals(provider)) {
            // 직접 접근 방식 먼저 시도
            if (attributes.containsKey("id")) {
                return String.valueOf(attributes.get("id"));
            }

            // 중첩된 방식 시도
            Map<String, Object> response = (Map<String, Object>) attributes.get("response");
            return response != null ? String.valueOf(response.get("id")) : null;
        }
        return null;
    }

}