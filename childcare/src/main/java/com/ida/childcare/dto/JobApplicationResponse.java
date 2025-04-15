package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// 지원서 응답 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobApplicationResponse {
    private Long id; // 지원서 ID
    private Long jobPostingId; // 구인글 ID
    private String jobTitle; // 구인글 제목
    private Long sitterId; // 시터 ID
    private String sitterEmail; // 시터 이메일
    private String coverLetter; // 자기소개/지원 메시지
    private Double proposedHourlyRate; // 제안 시급
    private String status; // 지원 상태
    private LocalDateTime createdAt; // 생성 시간
    private LocalDateTime updatedAt; // 수정 시간
}