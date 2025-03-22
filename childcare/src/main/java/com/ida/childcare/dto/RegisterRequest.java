package com.ida.childcare.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {
    private String email;
    private String password;
    private String phoneNumber;
    private String userType; // "PARENT", "SITTER", "ADMIN"
}