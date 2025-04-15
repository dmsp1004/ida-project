package com.ida.childcare.service;

import com.ida.childcare.dto.*;
import com.ida.childcare.entity.*;
import com.ida.childcare.repository.JobApplicationRepository;
import com.ida.childcare.repository.JobPostingRepository;
import com.ida.childcare.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class JobPostingService {

    private final JobPostingRepository jobPostingRepository;
    private final UserRepository userRepository;
    private final JobApplicationRepository jobApplicationRepository;

    @Autowired
    public JobPostingService(JobPostingRepository jobPostingRepository,
                             UserRepository userRepository,
                             JobApplicationRepository jobApplicationRepository) {
        this.jobPostingRepository = jobPostingRepository;
        this.userRepository = userRepository;
        this.jobApplicationRepository = jobApplicationRepository;
    }

    // 구인글 생성
    @Transactional
    public JobPostingResponse createJobPosting(String email, JobPostingRequest request) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 부모 사용자 확인
        if (!(user instanceof Parent)) {
            throw new AccessDeniedException("부모 회원만 구인글을 작성할 수 있습니다.");
        }

        Parent parent = (Parent) user;

        // 구인글 생성
        JobPosting jobPosting = new JobPosting();
        jobPosting.setTitle(request.getTitle());
        jobPosting.setDescription(request.getDescription());
        jobPosting.setParent(parent);
        jobPosting.setLocation(request.getLocation());
        jobPosting.setStartDate(request.getStartDate());
        jobPosting.setEndDate(request.getEndDate());
        jobPosting.setHourlyRate(request.getHourlyRate());
        jobPosting.setRequiredExperienceYears(request.getRequiredExperienceYears());
        jobPosting.setAgeOfChildren(request.getAgeOfChildren());
        jobPosting.setNumberOfChildren(request.getNumberOfChildren());
        jobPosting.setIsActive(true);

        // 구인 유형 설정
        try {
            JobPosting.JobType jobType = JobPosting.JobType.valueOf(request.getJobType());
            jobPosting.setJobType(jobType);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("잘못된 구인 유형입니다: " + request.getJobType());
        }

        // 저장
        JobPosting savedJobPosting = jobPostingRepository.save(jobPosting);

        // 응답 생성
        return convertToJobPostingResponse(savedJobPosting);
    }

    // 구인글 수정
    @Transactional
    public JobPostingResponse updateJobPosting(String email, Long jobPostingId, JobPostingRequest request) {
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
                throw new AccessDeniedException("해당 구인글을 수정할 권한이 없습니다.");
            }
        } else if (user instanceof Admin) {
            // 관리자는 모든 구인글 수정 가능
        } else {
            throw new AccessDeniedException("구인글을 수정할 권한이 없습니다.");
        }

        // 구인글 업데이트
        jobPosting.setTitle(request.getTitle());
        jobPosting.setDescription(request.getDescription());
        jobPosting.setLocation(request.getLocation());
        jobPosting.setStartDate(request.getStartDate());
        jobPosting.setEndDate(request.getEndDate());
        jobPosting.setHourlyRate(request.getHourlyRate());
        jobPosting.setRequiredExperienceYears(request.getRequiredExperienceYears());
        jobPosting.setAgeOfChildren(request.getAgeOfChildren());
        jobPosting.setNumberOfChildren(request.getNumberOfChildren());

        // 구인 유형 설정
        try {
            JobPosting.JobType jobType = JobPosting.JobType.valueOf(request.getJobType());
            jobPosting.setJobType(jobType);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("잘못된 구인 유형입니다: " + request.getJobType());
        }

        // 저장
        JobPosting updatedJobPosting = jobPostingRepository.save(jobPosting);

        // 응답 생성
        return convertToJobPostingResponse(updatedJobPosting);
    }

    // 구인글 상세 조회
    @Transactional(readOnly = true)
    public JobPostingResponse getJobPosting(Long jobPostingId) {
        JobPosting jobPosting = jobPostingRepository.findById(jobPostingId)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 구인글을 찾을 수 없습니다: " + jobPostingId));

        return convertToJobPostingResponse(jobPosting);
    }

    // 구인글 비활성화 (삭제 대신)
    @Transactional
    public void deactivateJobPosting(String email, Long jobPostingId) {
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
                throw new AccessDeniedException("해당 구인글을 수정할 권한이 없습니다.");
            }
        } else if (user instanceof Admin) {
            // 관리자는 모든 구인글 수정 가능
        } else {
            throw new AccessDeniedException("구인글을 수정할 권한이 없습니다.");
        }

        // 구인글 비활성화
        jobPosting.setIsActive(false);
        jobPostingRepository.save(jobPosting);
    }

    // 모든 활성화된 구인글 목록 조회 (페이징)
    @Transactional(readOnly = true)
    public JobPostingListResponse getAllActiveJobPostings(Pageable pageable) {
        Page<JobPosting> jobPostings = jobPostingRepository.findByIsActiveTrue(pageable);

        List<JobPostingResponse> content = jobPostings.getContent().stream()
                .map(this::convertToJobPostingResponse)
                .collect(Collectors.toList());

        return JobPostingListResponse.builder()
                .content(content)
                .pageNumber(jobPostings.getNumber())
                .pageSize(jobPostings.getSize())
                .totalElements(jobPostings.getTotalElements())
                .totalPages(jobPostings.getTotalPages())
                .last(jobPostings.isLast())
                .build();
    }

    // 특정 부모가 작성한 구인글 목록 조회
    @Transactional(readOnly = true)
    public JobPostingListResponse getJobPostingsByParent(String email, Pageable pageable) {
        // 이메일로 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자를 찾을 수 없습니다: " + email));

        // 부모 사용자 확인
        if (!(user instanceof Parent)) {
            throw new AccessDeniedException("부모 회원만 자신의 구인글을 조회할 수 있습니다.");
        }

        Parent parent = (Parent) user;
        Page<JobPosting> jobPostings = jobPostingRepository.findByParent(parent, pageable);

        List<JobPostingResponse> content = jobPostings.getContent().stream()
                .map(this::convertToJobPostingResponse)
                .collect(Collectors.toList());

        return JobPostingListResponse.builder()
                .content(content)
                .pageNumber(jobPostings.getNumber())
                .pageSize(jobPostings.getSize())
                .totalElements(jobPostings.getTotalElements())
                .totalPages(jobPostings.getTotalPages())
                .last(jobPostings.isLast())
                .build();
    }

    // 키워드로 구인글 검색
    @Transactional(readOnly = true)
    public JobPostingListResponse searchJobPostings(String keyword, Pageable pageable) {
        Page<JobPosting> jobPostings = jobPostingRepository.findByIsActiveTrueAndTitleContainingOrDescriptionContaining(
                keyword, keyword, pageable);

        List<JobPostingResponse> content = jobPostings.getContent().stream()
                .map(this::convertToJobPostingResponse)
                .collect(Collectors.toList());

        return JobPostingListResponse.builder()
                .content(content)
                .pageNumber(jobPostings.getNumber())
                .pageSize(jobPostings.getSize())
                .totalElements(jobPostings.getTotalElements())
                .totalPages(jobPostings.getTotalPages())
                .last(jobPostings.isLast())
                .build();
    }

    // 지역으로 구인글 검색
    @Transactional(readOnly = true)
    public JobPostingListResponse searchJobPostingsByLocation(String location, Pageable pageable) {
        Page<JobPosting> jobPostings = jobPostingRepository.findByIsActiveTrueAndLocationContaining(location, pageable);

        List<JobPostingResponse> content = jobPostings.getContent().stream()
                .map(this::convertToJobPostingResponse)
                .collect(Collectors.toList());

        return JobPostingListResponse.builder()
                .content(content)
                .pageNumber(jobPostings.getNumber())
                .pageSize(jobPostings.getSize())
                .totalElements(jobPostings.getTotalElements())
                .totalPages(jobPostings.getTotalPages())
                .last(jobPostings.isLast())
                .build();
    }

    // JobPosting 엔티티를 JobPostingResponse DTO로 변환
    private JobPostingResponse convertToJobPostingResponse(JobPosting jobPosting) {
        int applicationCount = jobApplicationRepository.countApplicationsByJobPostingId(jobPosting.getId());

        return JobPostingResponse.builder()
                .id(jobPosting.getId())
                .title(jobPosting.getTitle())
                .description(jobPosting.getDescription())
                .parentId(jobPosting.getParent().getId())
                .parentName(jobPosting.getParent().getEmail()) // User 클래스에 name 필드가 없어 이메일로 대체
                .location(jobPosting.getLocation())
                .startDate(jobPosting.getStartDate())
                .endDate(jobPosting.getEndDate())
                .hourlyRate(jobPosting.getHourlyRate())
                .requiredExperienceYears(jobPosting.getRequiredExperienceYears())
                .jobType(jobPosting.getJobType().name())
                .ageOfChildren(jobPosting.getAgeOfChildren())
                .numberOfChildren(jobPosting.getNumberOfChildren())
                .isActive(jobPosting.getIsActive())
                .createdAt(jobPosting.getCreatedAt())
                .updatedAt(jobPosting.getUpdatedAt())
                .applicationCount(applicationCount)
                .build();
    }
}