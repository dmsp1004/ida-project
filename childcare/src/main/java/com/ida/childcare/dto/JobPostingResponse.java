package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// 구인글 응답 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobPostingResponse {
    private Long id; // 구인글 ID
    private String title; // 제목
    private String description; // 상세 내용
    private Long parentId; // 부모 ID
    private String parentName; // 부모 이름 (수정필요 - User에 name 필드가 없음)
    private String location; // 위치/주소
    private LocalDateTime startDate; // 시작 날짜/시간
    private LocalDateTime endDate; // 종료 날짜/시간
    private Double hourlyRate; // 시간당 급여
    private Integer requiredExperienceYears; // 요구 경력 연수
    private String jobType; // 구인 유형
    private String ageOfChildren; // 아이 나이
    private Integer numberOfChildren; // 아이 숫자
    private Boolean isActive; // 활성화 상태
    private LocalDateTime createdAt; // 생성 시간
    private LocalDateTime updatedAt; // 수정 시간
    private Integer applicationCount; // 지원자 수
}
