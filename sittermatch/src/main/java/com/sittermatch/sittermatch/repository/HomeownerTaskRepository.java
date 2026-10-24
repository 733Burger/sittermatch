package com.sittermatch.sittermatch.repository;

import com.sittermatch.sittermatch.model.HomeownerTask;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HomeownerTaskRepository extends JpaRepository<HomeownerTask, Integer> {
    List<HomeownerTask> findByHomeownerIdOrderByIdAsc(Integer homeownerId);
}
