package com.ida.childcare.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "job_postings")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class JobPosting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title; // 제목

    @Column(columnDefinition = "TEXT")
    private String description; // 상세 내용

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id", nullable = false)
    private Parent parent; // 작성자(부모)

    @Column(name = "location")
    private String location; // 위치/주소

    @Column(name = "start_date")
    private LocalDateTime startDate; // 시작 날짜/시간

    @Column(name = "end_date")
    private LocalDateTime endDate; // 종료 날짜/시간

    @Column(name = "hourly_rate")
    private Double hourlyRate; // 시간당 급여

    @Column(name = "required_experience_years")
    private Integer requiredExperienceYears; // 요구 경력 연수

    @Column(name = "is_active")
    private Boolean isActive = true; // 활성화 상태 (구인중/마감)

    @Column(name = "age_of_children")
    private String ageOfChildren; // 아이 나이

    @Column(name = "number_of_children")
    private Integer numberOfChildren; // 아이 숫자

    @Enumerated(EnumType.STRING)
    @Column(name = "job_type")
    private JobType jobType; // 구인 유형

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt; // 생성 시간

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt; // 수정 시간

    @OneToMany(mappedBy = "jobPosting", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<JobApplication> applications = new HashSet<>(); // 지원 목록

    public enum JobType {
        REGULAR_CARE, // 정기 돌봄
        SCHOOL_ESCORT, // 등하원 도우미
        ONE_TIME, // 일회성 돌봄
        EMERGENCY // 긴급 돌봄
    }
}

