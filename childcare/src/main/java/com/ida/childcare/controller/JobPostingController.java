package com.ida.childcare.controller;

import com.ida.childcare.dto.JobPostingListResponse;
import com.ida.childcare.dto.JobPostingRequest;
import com.ida.childcare.dto.JobPostingResponse;
import com.ida.childcare.service.JobPostingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/job-postings")
public class JobPostingController {

    private final JobPostingService jobPostingService;

    @Autowired
    public JobPostingController(JobPostingService jobPostingService) {
        this.jobPostingService = jobPostingService;
    }

    // 구인글 생성
    @PostMapping
    public ResponseEntity<JobPostingResponse> createJobPosting(
            Authentication authentication,
            @RequestBody JobPostingRequest request) {
        String email = authentication.getName();
        JobPostingResponse response = jobPostingService.createJobPosting(email, request);
        return ResponseEntity.ok(response);
    }

    // 구인글 수정
    @PutMapping("/{id}")
    public ResponseEntity<JobPostingResponse> updateJobPosting(
            Authentication authentication,
            @PathVariable("id") Long jobPostingId,
            @RequestBody JobPostingRequest request) {
        String email = authentication.getName();
        JobPostingResponse response = jobPostingService.updateJobPosting(email, jobPostingId, request);
        return ResponseEntity.ok(response);
    }

    // 구인글 상세 조회
    @GetMapping("/{id}")
    public ResponseEntity<JobPostingResponse> getJobPosting(@PathVariable("id") Long jobPostingId) {
        JobPostingResponse response = jobPostingService.getJobPosting(jobPostingId);
        return ResponseEntity.ok(response);
    }

    // 구인글 비활성화
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deactivateJobPosting(
            Authentication authentication,
            @PathVariable("id") Long jobPostingId) {
        String email = authentication.getName();
        jobPostingService.deactivateJobPosting(email, jobPostingId);
        return ResponseEntity.ok(Map.of("success", true, "message", "구인글이 비활성화되었습니다."));
    }

    // 모든 활성화된 구인글 목록 조회 (페이징)
    @GetMapping
    public ResponseEntity<JobPostingListResponse> getAllActiveJobPostings(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sort,
            @RequestParam(defaultValue = "DESC") String direction) {

        Sort.Direction sortDirection = Sort.Direction.fromString(direction);
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sort));

        JobPostingListResponse response = jobPostingService.getAllActiveJobPostings(pageable);
        return ResponseEntity.ok(response);
    }

    // 내가 작성한 구인글 목록 조회
    @GetMapping("/my-postings")
    public ResponseEntity<JobPostingListResponse> getMyJobPostings(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sort,
            @RequestParam(defaultValue = "DESC") String direction) {

        String email = authentication.getName();
        Sort.Direction sortDirection = Sort.Direction.fromString(direction);
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sort));

        JobPostingListResponse response = jobPostingService.getJobPostingsByParent(email, pageable);
        return ResponseEntity.ok(response);
    }

    // 키워드로 구인글 검색
    @GetMapping("/search")
    public ResponseEntity<JobPostingListResponse> searchJobPostings(
            @RequestParam("keyword") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sort,
            @RequestParam(defaultValue = "DESC") String direction) {

        Sort.Direction sortDirection = Sort.Direction.fromString(direction);
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sort));

        JobPostingListResponse response = jobPostingService.searchJobPostings(keyword, pageable);
        return ResponseEntity.ok(response);
    }

    // 지역으로 구인글 검색
    @GetMapping("/search/location")
    public ResponseEntity<JobPostingListResponse> searchJobPostingsByLocation(
            @RequestParam("location") String location,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sort,
            @RequestParam(defaultValue = "DESC") String direction) {

        Sort.Direction sortDirection = Sort.Direction.fromString(direction);
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sort));

        JobPostingListResponse response = jobPostingService.searchJobPostingsByLocation(location, pageable);
        return ResponseEntity.ok(response);
    }
}
