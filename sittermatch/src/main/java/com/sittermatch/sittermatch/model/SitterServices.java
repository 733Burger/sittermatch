package com.sittermatch.sittermatch.model;

import java.math.BigDecimal;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class SitterServices {

    @Column(name = "service_type", nullable = false, length = 45)
    private String serviceType;

    @Column(name = "price", nullable = false, precision = 10, scale = 2)
    private BigDecimal price = BigDecimal.ZERO;

    public SitterServices() {
    }

    public SitterServices(String serviceType, BigDecimal price) {
        this.serviceType = serviceType;
        this.price = price;
    }

    public String getServiceType() {
        return serviceType;
    }

    public void setServiceType(String serviceType) {
        this.serviceType = serviceType;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof SitterServices that)) {
            return false;
        }
        return Objects.equals(serviceType, that.serviceType);
    }

    @Override
    public int hashCode() {
        return Objects.hash(serviceType);
    }
}