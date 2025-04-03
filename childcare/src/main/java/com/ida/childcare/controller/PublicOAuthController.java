package com.ida.childcare.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/public/oauth")
public class PublicOAuthController {

    /**
     * 소셜 로그인 임시 세션 정보를 저장하는 엔드포인트
     * 프론트엔드에서 소셜 인증 후 정보를 임시로 서버에 저장하기 위한 용도
     */
    @GetMapping("/store-session")
    public ResponseEntity<?> storeOAuthSession(
            @RequestParam("email") String email,
            @RequestParam("provider") String provider,
            @RequestParam(value = "providerId", required = false) String providerId,
            @RequestParam(value = "redirectUrl", required = false) String redirectUrl,
            @RequestParam(value = "mode", required = false) String mode,
            HttpSession session) {

        // 세션에 소셜 로그인 정보 저장
        session.setAttribute("oauth_email", email);
        session.setAttribute("oauth_provider", provider);
        session.setAttribute("oauth_mode", mode); // 로그인/회원가입 모드 저장

        if (providerId != null && !providerId.isEmpty()) {
            session.setAttribute("oauth_providerId", providerId);
        }

        // 세션 ID 반환 (프론트엔드에서 활용 가능)
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "소셜 로그인 정보가 임시 저장되었습니다");
        response.put("sessionId", session.getId());

        // 리다이렉트 URL이 제공된 경우 해당 URL로 리다이렉트
        if (redirectUrl != null && !redirectUrl.isEmpty()) {
            response.put("redirectUrl", redirectUrl);
            return ResponseEntity.ok(response);
        }

        // 기본 리다이렉트 URL
        response.put("redirectUrl", "/oauth-test.html");
        return ResponseEntity.ok(response);
    }

    /**
     * 세션에 저장된 소셜 로그인 정보를 확인하는 엔드포인트
     */
    @GetMapping("/check-session")
    public ResponseEntity<?> checkOAuthSession(HttpSession session) {
        String email = (String) session.getAttribute("oauth_email");
        String provider = (String) session.getAttribute("oauth_provider");
        String providerId = (String) session.getAttribute("oauth_providerId");
        String mode = (String) session.getAttribute("oauth_mode");

        Map<String, Object> response = new HashMap<>();
        boolean hasOAuthInfo = email != null && provider != null;

        response.put("hasOAuthInfo", hasOAuthInfo);

        if (hasOAuthInfo) {
            response.put("email", email);
            response.put("provider", provider);

            if (providerId != null) {
                response.put("providerId", providerId);
            }

            if (mode != null) {
                response.put("mode", mode);
            }
        }

        return ResponseEntity.ok(response);
    }

    /**
     * 세션에 저장된 소셜 로그인 정보를 삭제하는 엔드포인트
     */
    @GetMapping("/clear-session")
    public ResponseEntity<?> clearOAuthSession(HttpSession session) {
        session.removeAttribute("oauth_email");
        session.removeAttribute("oauth_provider");
        session.removeAttribute("oauth_providerId");
        session.removeAttribute("oauth_mode");

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "소셜 로그인 세션 정보가 삭제되었습니다");

        return ResponseEntity.ok(response);
    }
}