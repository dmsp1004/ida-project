package com.ida.childcare.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "job_applications")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class JobApplication {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "job_posting_id", nullable = false)
    private JobPosting jobPosting; // 연결된 구인글

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sitter_id", nullable = false)
    private Sitter sitter; // 지원자(시터)

    @Column(columnDefinition = "TEXT")
    private String coverLetter; // 자기소개/지원 메시지

    @Column(name = "proposed_hourly_rate")
    private Double proposedHourlyRate; // 제안 시급

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ApplicationStatus status = ApplicationStatus.PENDING; // 지원 상태

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt; // 생성 시간

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt; // 수정 시간

    public enum ApplicationStatus {
        PENDING, // 대기중
        ACCEPTED, // 수락됨
        REJECTED, // 거절됨
        WITHDRAWN // 철회됨
    }
}
