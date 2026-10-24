package com.sittermatch.sittermatch.controller;

import com.sittermatch.sittermatch.dto.TaskRequest;
import com.sittermatch.sittermatch.services.TaskService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;
import java.util.function.Supplier;

/** The homeowner's stay checklist, and the sitter ticking it off day by day on a booking. */
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @GetMapping("/home/{homeownerId}/tasks")
    public ResponseEntity<?> getHomeownerTasks(@PathVariable Integer homeownerId) {
        return ResponseEntity.ok(taskService.getHomeownerTasks(homeownerId));
    }

    @PostMapping("/home/{homeownerId}/tasks")
    public ResponseEntity<?> addTask(@PathVariable Integer homeownerId, @RequestBody TaskRequest request) {
        return handle(() -> taskService.addTask(homeownerId, request));
    }

    @PutMapping("/home/{homeownerId}/tasks/{taskId}")
    public ResponseEntity<?> updateTask(@PathVariable Integer homeownerId, @PathVariable Integer taskId,
                                        @RequestBody TaskRequest request) {
        return handle(() -> taskService.updateTask(homeownerId, taskId, request));
    }

    @DeleteMapping("/home/{homeownerId}/tasks/{taskId}")
    public ResponseEntity<?> deleteTask(@PathVariable Integer homeownerId, @PathVariable Integer taskId) {
        return handle(() -> {
            taskService.deleteTask(homeownerId, taskId);
            return Map.of("success", true);
        });
    }

    /** The booking's checklist for one day (defaults to today), with what the sitter has ticked off. */
    @GetMapping("/bookings/{bookingId}/tasks")
    public ResponseEntity<?> getBookingTasks(@PathVariable Integer bookingId,
                                             @RequestParam(required = false)
                                             @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return handle(() -> taskService.getBookingTasks(bookingId, date != null ? date : LocalDate.now()));
    }

    @PutMapping("/bookings/{bookingId}/tasks/{taskId}")
    public ResponseEntity<?> setTaskDone(@PathVariable Integer bookingId, @PathVariable Integer taskId,
                                         @RequestParam boolean done,
                                         @RequestParam(required = false)
                                         @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return handle(() -> taskService.setTaskDone(bookingId, taskId, date != null ? date : LocalDate.now(), done));
    }

    private ResponseEntity<?> handle(Supplier<Object> action) {
        try {
            return ResponseEntity.ok(action.get());
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}
