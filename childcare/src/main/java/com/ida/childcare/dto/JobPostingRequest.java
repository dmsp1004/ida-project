package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// 구인글 생성/수정 요청 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobPostingRequest {
    private String title; // 제목
    private String description; // 상세 내용
    private String location; // 위치/주소
    private LocalDateTime startDate; // 시작 날짜/시간
    private LocalDateTime endDate; // 종료 날짜/시간
    private Double hourlyRate; // 시간당 급여
    private Integer requiredExperienceYears; // 요구 경력 연수
    private String jobType; // 구인 유형 (REGULAR_CARE, SCHOOL_ESCORT, ONE_TIME, EMERGENCY)
    private String ageOfChildren; // 아이 나이
    private Integer numberOfChildren; // 아이 숫자
}
