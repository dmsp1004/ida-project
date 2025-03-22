package com.ida.childcare.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "parents")
@DiscriminatorValue("PARENT")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
public class Parent extends User {

    @Column(name = "number_of_children")
    private Integer numberOfChildren;

    @Column(name = "address")
    private String address;

    @Column(name = "additional_info", columnDefinition = "TEXT")
    private String additionalInfo;
}