package com.ida.childcare.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "admins")
@DiscriminatorValue("ADMIN")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
public class Admin extends User {

    @Column(name = "department")
    private String department;

    @Column(name = "admin_level")
    private Integer adminLevel = 1; // 기본값 1 (일반 관리자)

    @Column(name = "access_all_records")
    private Boolean accessAllRecords = false;
}