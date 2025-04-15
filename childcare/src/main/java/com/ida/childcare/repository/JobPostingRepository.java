package com.ida.childcare.repository;

import com.ida.childcare.entity.JobPosting;
import com.ida.childcare.entity.Parent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface JobPostingRepository extends JpaRepository<JobPosting, Long> {

    // 활성화된 모든 구인글 검색 (페이징)
    Page<JobPosting> findByIsActiveTrue(Pageable pageable);

    // 특정 부모가 작성한 구인글 검색
    Page<JobPosting> findByParent(Parent parent, Pageable pageable);

    // 제목 또는 설명에 특정 키워드가 포함된 구인글 검색
    Page<JobPosting> findByIsActiveTrueAndTitleContainingOrDescriptionContaining(
            String titleKeyword, String descriptionKeyword, Pageable pageable);

    // 특정 위치에 있는 구인글 검색
    Page<JobPosting> findByIsActiveTrueAndLocationContaining(String location, Pageable pageable);

    // 특정 유형의 구인글 검색
    Page<JobPosting> findByIsActiveTrueAndJobType(JobPosting.JobType jobType, Pageable pageable);

    // 특정 시간 범위에 있는 구인글 검색
    @Query("SELECT jp FROM JobPosting jp WHERE jp.isActive = true AND " +
            "((jp.startDate BETWEEN :startTime AND :endTime) OR " +
            "(jp.endDate BETWEEN :startTime AND :endTime) OR " +
            "(jp.startDate <= :startTime AND jp.endDate >= :endTime))")
    Page<JobPosting> findAvailableJobPostingsInTimeRange(
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime,
            Pageable pageable);

    // 특정 시급 이상인 구인글 검색
    Page<JobPosting> findByIsActiveTrueAndHourlyRateGreaterThanEqual(Double minHourlyRate, Pageable pageable);
}