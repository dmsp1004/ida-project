package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

// 지원서 생성/수정 요청 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobApplicationRequest {
    private Long jobPostingId; // 구인글 ID
    private String coverLetter; // 자기소개/지원 메시지
    private Double proposedHourlyRate; // 제안 시급
}