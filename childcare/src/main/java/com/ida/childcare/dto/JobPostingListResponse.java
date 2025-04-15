package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

// 구인글 목록 응답 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobPostingListResponse {
    private List<JobPostingResponse> content; // 구인글 목록
    private int pageNumber; // 현재 페이지
    private int pageSize; // 페이지 크기
    private long totalElements; // 전체 요소 수
    private int totalPages; // 전체 페이지 수
    private boolean last; // 마지막 페이지 여부
}
