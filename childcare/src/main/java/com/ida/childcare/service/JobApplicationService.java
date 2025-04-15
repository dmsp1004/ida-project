package com.ida.childcare.service;

import com.ida.childcare.dto.JobApplicationRequest;
import com.ida.childcare.dto.JobApplicationResponse;
import com.ida.childcare.entity.*;
import com.ida.childcare.repository.JobApplicationRepository;
import com.ida.childcare.repository.JobPostingRepository;
import com.ida.childcare.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class JobApplicationService {

    private final JobApplicationRepository jobApplicationRepository;
    private final JobPostingRepository jobPostingRepository;
    private final UserRepository userRepository;

    @Autowired
    public JobApplicationService(JobApplicationRepository jobApplicationRepository,
                                 JobPostingRepository jobPostingRepository,
                                 UserRepository userRepository) {
        this.jobApplicationRepository = jobApplicationRepository;
        this.jobPostingRepository = jobPostingRepository;
        this.userRepository = userRepository;
    }

    // 지원서 제출
    @Transactional
    public JobApplicationResponse applyToJob(String email, JobApplicationRequest request) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 시터 사용자 확인
        if (!(user instanceof Sitter)) {
            throw new AccessDeniedException("시터 회원만 구인글에 지원할 수 있습니다.");
        }

        Sitter sitter = (Sitter) user;

        // 구인글 조회
        JobPosting jobPosting = jobPostingRepository.findById(request.getJobPostingId())
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 구인글을 찾을 수 없습니다: " + request.getJobPostingId()));

        // 구인글 활성화 상태 확인
        if (!jobPosting.getIsActive()) {
            throw new IllegalArgumentException("비활성화된 구인글에는 지원할 수 없습니다.");
        }

        // 이미 지원했는지 확인
        if (jobApplicationRepository.existsByJobPostingIdAndSitterId(jobPosting.getId(), sitter.getId())) {
            throw new IllegalArgumentException("이미 해당 구인글에 지원하셨습니다.");
        }

        // 지원서 생성
        JobApplication jobApplication = new JobApplication();
        jobApplication.setJobPosting(jobPosting);
        jobApplication.setSitter(sitter);
        jobApplication.setCoverLetter(request.getCoverLetter());
        jobApplication.setProposedHourlyRate(request.getProposedHourlyRate());
        jobApplication.setStatus(JobApplication.ApplicationStatus.PENDING);

        // 저장
        JobApplication savedJobApplication = jobApplicationRepository.save(jobApplication);

        // 응답 생성
        return convertToJobApplicationResponse(savedJobApplication);
    }

    // 지원서 철회
    @Transactional
    public void withdrawApplication(String email, Long applicationId) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 지원서 조회
        JobApplication jobApplication = jobApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 지원서를 찾을 수 없습니다: " + applicationId));

        // 권한 확인
        if (user instanceof Sitter) {
            Sitter sitter = (Sitter) user;
            if (!jobApplication.getSitter().getId().equals(sitter.getId())) {
                throw new AccessDeniedException("해당 지원서를 철회할 권한이 없습니다.");
            }
        } else {
            throw new AccessDeniedException("시터 회원만 지원서를 철회할 수 있습니다.");
        }

        // 지원서 상태 변경
        jobApplication.setStatus(JobApplication.ApplicationStatus.WITHDRAWN);
        jobApplicationRepository.save(jobApplication);
    }

    // 지원서 수락/거절
    @Transactional
    public JobApplicationResponse updateApplicationStatus(String email, Long applicationId, String status) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 지원서 조회
        JobApplication jobApplication = jobApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 지원서를 찾을 수 없습니다: " + applicationId));

        // 권한 확인
        if (user instanceof Parent) {
            Parent parent = (Parent) user;
            if (!jobApplication.getJobPosting().getParent().getId().equals(parent.getId())) {
                throw new AccessDeniedException("해당 지원서를 처리할 권한이 없습니다.");
            }
        } else if (user instanceof Admin) {
            // 관리자는 모든 지원서 처리 가능
        } else {
            throw new AccessDeniedException("부모 또는 관리자 회원만 지원서를 처리할 수 있습니다.");
        }

        // 상태 변경
        try {
            JobApplication.ApplicationStatus newStatus = JobApplication.ApplicationStatus.valueOf(status);
            jobApplication.setStatus(newStatus);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("잘못된 지원서 상태입니다: " + status);
        }

        // 저장
        JobApplication updatedJobApplication = jobApplicationRepository.save(jobApplication);

        // 응답 생성
        return convertToJobApplicationResponse(updatedJobApplication);
    }

    // 특정 구인글에 대한 지원서 목록 조회
    @Transactional(readOnly = true)
    public List<JobApplicationResponse> getApplicationsByJobPosting(String email, Long jobPostingId) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 구인글 조회
        JobPosting jobPosting = jobPostingRepository.findById(jobPostingId)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 구인글을 찾을 수 없습니다: " + jobPostingId));

        // 권한 확인
        if (user instanceof Parent) {
            Parent parent = (Parent) user;
            if (!jobPosting.getParent().getId().equals(parent.getId())) {
                throw new AccessDeniedException("해당 구인글의 지원서를 조회할 권한이 없습니다.");
            }
        } else if (user instanceof Admin) {
            // 관리자는 모든 구인글의 지원서 조회 가능
        } else {
            throw new AccessDeniedException("부모 또는 관리자 회원만 지원서를 조회할 수 있습니다.");
        }

        // 지원서 조회
        List<JobApplication> applications = jobApplicationRepository.findByJobPostingId(jobPostingId);

        // 응답 생성
        return applications.stream()
                .map(this::convertToJobApplicationResponse)
                .collect(Collectors.toList());
    }

    // 특정 시터의 지원서 목록 조회
    @Transactional(readOnly = true)
    public List<JobApplicationResponse> getMyApplications(String email) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 시터 사용자 확인
        if (!(user instanceof Sitter)) {
            throw new AccessDeniedException("시터 회원만 자신의 지원서를 조회할 수 있습니다.");
        }

        Sitter sitter = (Sitter) user;

        // 지원서 조회
        List<JobApplication> applications = jobApplicationRepository.findBySitter(sitter);

        // 응답 생성
        return applications.stream()
                .map(this::convertToJobApplicationResponse)
                .collect(Collectors.toList());
    }

    // 부모의 구인글에 대한 모든 지원서 조회
    @Transactional(readOnly = true)
    public List<JobApplicationResponse> getAllApplicationsForParent(String email) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 부모 사용자 확인
        if (!(user instanceof Parent)) {
            throw new AccessDeniedException("부모 회원만 자신의 구인글에 대한 지원서를 조회할 수 있습니다.");
        }

        Parent parent = (Parent) user;

        // 지원서 조회
        List<JobApplication> applications = jobApplicationRepository.findByJobPosting_Parent_Id(parent.getId());

        // 응답 생성
        return applications.stream()
                .map(this::convertToJobApplicationResponse)
                .collect(Collectors.toList());
    }

    // JobApplication 엔티티를 JobApplicationResponse DTO로 변환
    private JobApplicationResponse convertToJobApplicationResponse(JobApplication jobApplication) {
        return JobApplicationResponse.builder()
                .id(jobApplication.getId())
                .jobPostingId(jobApplication.getJobPosting().getId())
                .jobTitle(jobApplication.getJobPosting().getTitle())
                .sitterId(jobApplication.getSitter().getId())
                .sitterEmail(jobApplication.getSitter().getEmail())
                .coverLetter(jobApplication.getCoverLetter())
                .proposedHourlyRate(jobApplication.getProposedHourlyRate())
                .status(jobApplication.getStatus().name())
                .createdAt(jobApplication.getCreatedAt())
                .updatedAt(jobApplication.getUpdatedAt())
                .build();
    }
}