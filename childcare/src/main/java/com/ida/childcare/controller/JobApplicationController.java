package com.ida.childcare.controller;

import com.ida.childcare.dto.JobApplicationRequest;
import com.ida.childcare.dto.JobApplicationResponse;
import com.ida.childcare.service.JobApplicationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/job-applications")
public class JobApplicationController {

    private final JobApplicationService jobApplicationService;

    @Autowired
    public JobApplicationController(JobApplicationService jobApplicationService) {
        this.jobApplicationService = jobApplicationService;
    }

    // 지원서 제출
    @PostMapping
    public ResponseEntity<JobApplicationResponse> applyToJob(
            Authentication authentication,
            @RequestBody JobApplicationRequest request) {
        String email = authentication.getName();
        JobApplicationResponse response = jobApplicationService.applyToJob(email, request);
        return ResponseEntity.ok(response);
    }

    // 지원서 철회
    @DeleteMapping("/{id}")
    public ResponseEntity<?> withdrawApplication(
            Authentication authentication,
            @PathVariable("id") Long applicationId) {
        String email = authentication.getName();
        jobApplicationService.withdrawApplication(email, applicationId);
        return ResponseEntity.ok(Map.of("success", true, "message", "지원이 철회되었습니다."));
    }

    // 지원서 상태 변경 (수락/거절)
    @PatchMapping("/{id}/status")
    public ResponseEntity<JobApplicationResponse> updateApplicationStatus(
            Authentication authentication,
            @PathVariable("id") Long applicationId,
            @RequestBody Map<String, String> statusRequest) {

        String email = authentication.getName();
        String status = statusRequest.get("status");

        if (status == null) {
            return ResponseEntity.badRequest().build();
        }

        JobApplicationResponse response = jobApplicationService.updateApplicationStatus(email, applicationId, status);
        return ResponseEntity.ok(response);
    }

    // 특정 구인글에 대한 지원서 목록 조회
    @GetMapping("/by-posting/{postingId}")
    public ResponseEntity<List<JobApplicationResponse>> getApplicationsByJobPosting(
            Authentication authentication,
            @PathVariable("postingId") Long jobPostingId) {
        String email = authentication.getName();
        List<JobApplicationResponse> response = jobApplicationService.getApplicationsByJobPosting(email, jobPostingId);
        return ResponseEntity.ok(response);
    }

    // 내가 제출한 지원서 목록 조회
    @GetMapping("/my-applications")
    public ResponseEntity<List<JobApplicationResponse>> getMyApplications(Authentication authentication) {
        String email = authentication.getName();
        List<JobApplicationResponse> response = jobApplicationService.getMyApplications(email);
        return ResponseEntity.ok(response);
    }

    // 나의 구인글에 대한 모든 지원서 목록 조회
    @GetMapping("/all-for-parent")
    public ResponseEntity<List<JobApplicationResponse>> getAllApplicationsForParent(Authentication authentication) {
        String email = authentication.getName();
        List<JobApplicationResponse> response = jobApplicationService.getAllApplicationsForParent(email);
        return ResponseEntity.ok(response);
    }
}