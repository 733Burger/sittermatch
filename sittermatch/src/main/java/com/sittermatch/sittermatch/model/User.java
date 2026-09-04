package com.sittermatch.sittermatch.model;

import java.sql.Date;

public class User {
    private int ID;
    private String name;
    private String email;
    private String phone;
    private String active_role;
    private Boolean is_valid_homeowner;
    private Boolean is_valid_sitter;
    private Date created_at;

    public User() {}

    public User(int ID, String name, String email, String phone, String active_role, Boolean is_valid_homeowner, Boolean is_valid_sitter, Date created_at) {
        this.ID = ID;
        this.name = name;
        this.email = email;
        this.phone = phone;
        this.active_role = active_role;
        this.is_valid_homeowner = is_valid_homeowner;
        this.is_valid_sitter = is_valid_sitter;
        this.created_at = created_at;
    }

    public int getId() {
        return ID;
    }

    public void setId(int ID) {
        this.ID = ID;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getActive_role() {
        return active_role;
    }

    public void setActive_role(String active_role) {
        this.active_role = active_role;
    }

    public Boolean getIs_valid_homeowner() {
        return is_valid_homeowner;
    }

    public void setIs_valid_homeowner(Boolean is_valid_homeowner) {
        this.is_valid_homeowner = is_valid_homeowner;
    }

    public Boolean getIs_valid_sitter() {
        return is_valid_sitter;
    }

    public void setIs_valid_sitter(Boolean is_valid_sitter) {
        this.is_valid_sitter = is_valid_sitter;
    }

    public Date getCreated_at() {
        return created_at;
    }

    public void setCreated_at(Date created_at) {
        this.created_at = created_at;
    }
}
