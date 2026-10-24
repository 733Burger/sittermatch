package com.sittermatch.sittermatch.services;

import com.sittermatch.sittermatch.dto.TaskRequest;
import com.sittermatch.sittermatch.dto.TaskResponse;
import com.sittermatch.sittermatch.model.Booking;
import com.sittermatch.sittermatch.model.BookingTaskCheck;
import com.sittermatch.sittermatch.model.Homeowner;
import com.sittermatch.sittermatch.model.HomeownerTask;
import com.sittermatch.sittermatch.repository.BookingRepository;
import com.sittermatch.sittermatch.repository.BookingTaskCheckRepository;
import com.sittermatch.sittermatch.repository.HomeownerRepository;
import com.sittermatch.sittermatch.repository.HomeownerTaskRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** The homeowner's stay checklist, and the sitter's daily ticks on each booking. */
@Service
public class TaskService {

    private final HomeownerTaskRepository taskRepository;
    private final BookingTaskCheckRepository checkRepository;
    private final HomeownerRepository homeownerRepository;
    private final BookingRepository bookingRepository;

    public TaskService(HomeownerTaskRepository taskRepository,
                       BookingTaskCheckRepository checkRepository,
                       HomeownerRepository homeownerRepository,
                       BookingRepository bookingRepository) {
        this.taskRepository = taskRepository;
        this.checkRepository = checkRepository;
        this.homeownerRepository = homeownerRepository;
        this.bookingRepository = bookingRepository;
    }

    // ---------- Homeowner's checklist ----------

    public List<TaskResponse> getHomeownerTasks(Integer homeownerId) {
        return taskRepository.findByHomeownerIdOrderByIdAsc(homeownerId).stream()
                .map(t -> new TaskResponse(t.getId(), t.getTitle(), t.getNote(), false, null))
                .collect(Collectors.toList());
    }

    public TaskResponse addTask(Integer homeownerId, TaskRequest request) {
        Homeowner owner = homeownerRepository.findById(homeownerId)
                .orElseThrow(() -> new IllegalArgumentException("Homeowner not found"));
        HomeownerTask task = new HomeownerTask();
        task.setHomeowner(owner);
        apply(task, request);
        HomeownerTask saved = taskRepository.save(task);
        return new TaskResponse(saved.getId(), saved.getTitle(), saved.getNote(), false, null);
    }

    public TaskResponse updateTask(Integer homeownerId, Integer taskId, TaskRequest request) {
        HomeownerTask task = ownTask(homeownerId, taskId);
        apply(task, request);
        HomeownerTask saved = taskRepository.save(task);
        return new TaskResponse(saved.getId(), saved.getTitle(), saved.getNote(), false, null);
    }

    /** Deleting a task also removes its ticks on bookings (the database cascades). */
    public void deleteTask(Integer homeownerId, Integer taskId) {
        taskRepository.delete(ownTask(homeownerId, taskId));
    }

    private HomeownerTask ownTask(Integer homeownerId, Integer taskId) {
        HomeownerTask task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        if (!task.getHomeowner().getId().equals(homeownerId)) {
            throw new IllegalArgumentException("Task not found");
        }
        return task;
    }

    private void apply(HomeownerTask task, TaskRequest request) {
        String title = request.title() == null ? "" : request.title().trim();
        if (title.isEmpty()) throw new IllegalArgumentException("Give the task a name.");
        if (title.length() > 100) throw new IllegalArgumentException("Task names can be up to 100 characters.");
        String note = request.note() == null ? "" : request.note().trim();
        if (note.length() > 255) throw new IllegalArgumentException("Task notes can be up to 255 characters.");
        task.setTitle(title);
        task.setNote(note.isEmpty() ? null : note);
    }

    // ---------- A booking's checklist for one day ----------

    public List<TaskResponse> getBookingTasks(Integer bookingId, LocalDate date) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found"));
        Integer homeownerId = booking.getListing().getHomeowner().getId();

        Map<Integer, BookingTaskCheck> checks = checkRepository.findByBookingIdAndCheckDate(bookingId, date).stream()
                .collect(Collectors.toMap(c -> c.getTask().getId(), Function.identity(), (a, b) -> a));

        return taskRepository.findByHomeownerIdOrderByIdAsc(homeownerId).stream()
                .map(t -> {
                    BookingTaskCheck check = checks.get(t.getId());
                    return new TaskResponse(t.getId(), t.getTitle(), t.getNote(),
                            check != null, check != null ? check.getCheckedAt() : null);
                })
                .collect(Collectors.toList());
    }

    /** The sitter ticks a task off (done = true) or unticks it for that day. */
    @Transactional
    public List<TaskResponse> setTaskDone(Integer bookingId, Integer taskId, LocalDate date, boolean done) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found"));
        HomeownerTask task = ownTask(booking.getListing().getHomeowner().getId(), taskId);

        var existing = checkRepository.findByBookingIdAndTaskIdAndCheckDate(bookingId, taskId, date);
        if (done && existing.isEmpty()) {
            BookingTaskCheck check = new BookingTaskCheck();
            check.setBooking(booking);
            check.setTask(task);
            check.setCheckDate(date);
            check.setCheckedAt(LocalDateTime.now());
            checkRepository.save(check);
        } else if (!done) {
            existing.ifPresent(checkRepository::delete);
        }
        return getBookingTasks(bookingId, date);
    }
}
