package com.ida.childcare.oauth;

import com.ida.childcare.entity.Parent;
import com.ida.childcare.entity.User;
import com.ida.childcare.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.lang.reflect.Field;
import java.util.*;

@Service
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    private final UserRepository userRepository;

    @Autowired
    public CustomOAuth2UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        System.out.println("OAuth2 로그인 요청: " + userRequest.getClientRegistration().getRegistrationId());
        OAuth2UserService<OAuth2UserRequest, OAuth2User> delegate = new DefaultOAuth2UserService();
        OAuth2User oAuth2User = delegate.loadUser(userRequest);

        // OAuth2 서비스 ID (google, kakao, naver)
        String registrationId = userRequest.getClientRegistration().getRegistrationId();

        // OAuth2 로그인 진행 시 키가 되는 필드 값 (PK)
        String userNameAttributeName = userRequest.getClientRegistration()
                .getProviderDetails().getUserInfoEndpoint().getUserNameAttributeName();

        // OAuth2UserService를 통해 가져온 데이터를 담을 클래스
        OAuthAttributes attributes = OAuthAttributes.of(
                registrationId,
                userNameAttributeName,
                oAuth2User.getAttributes()
        );

        User user = saveOrUpdate(attributes, registrationId);

        System.out.println("사용자 정보: " + attributes);
        System.out.println("사용자 저장/업데이트 결과: " + user);

        return new DefaultOAuth2User(
                Collections.singleton(new SimpleGrantedAuthority(user.getUserType().name())),
                attributes.getAttributes(),
                attributes.getNameAttributeKey()
        );
    }

    private User saveOrUpdate(OAuthAttributes attributes, String provider) {
        // 이메일로만 사용자 찾기
        User user = userRepository.findByEmail(attributes.getEmail())
                .orElse(null);

        if (user == null) {
            // 신규 사용자 생성 로직
            user = new Parent();
            user.setEmail(attributes.getEmail());
            // 비밀번호 설정
            user.setPassword("OAUTH2_" + UUID.randomUUID().toString());

            // userType 설정
            try {
                Field userTypeField = User.class.getDeclaredField("userType");
                userTypeField.setAccessible(true);
                userTypeField.set(user, User.UserType.PARENT);
            } catch (Exception e) {
                throw new RuntimeException("사용자 유형 설정 실패", e);
            }
        }

        // 소셜 로그인 정보 업데이트 (기존 사용자도 업데이트)
        user.setProvider(provider);
        user.setProviderId(attributes.getNameAttributeKey());

        return userRepository.save(user);
    }
}
