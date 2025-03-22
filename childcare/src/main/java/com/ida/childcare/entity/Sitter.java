package com.ida.childcare.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "sitters")
@DiscriminatorValue("SITTER")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
public class Sitter extends User {

    @Enumerated(EnumType.STRING)
    @Column(name = "sitter_type")
    private SitterType sitterType;

    @Column(name = "experience_years")
    private Integer experienceYears;

    @Column(name = "hourly_rate")
    private Double hourlyRate;

    @Column(name = "bio", columnDefinition = "TEXT")
    private String bio;

    @Column(name = "is_verified")
    private Boolean isVerified = false;

    @Column(name = "background_check_completed")
    private Boolean backgroundCheckCompleted = false;

    @Column(name = "interview_completed")
    private Boolean interviewCompleted = false;

    public enum SitterType {
        SCHOOL_ESCORT, REGULAR_SITTER
    }
}