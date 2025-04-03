package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OAuthRegisterRequest {
    private String email;
    private String phoneNumber;
    private String provider; // "google", "kakao", "naver"
    private String providerId;
    private String userType; // "PARENT", "SITTER"

    // 부모(Parent)에 필요한 추가 정보
    private Integer numberOfChildren;
    private String address;
    private String additionalInfo;

    // 시터(Sitter)에 필요한 추가 정보
    private String sitterType;  // "SCHOOL_ESCORT", "REGULAR_SITTER"
    private Integer experienceYears;
    private Double hourlyRate;
    private String bio;
}