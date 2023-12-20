-- Example of computing when a TimedHoldTask will be triggered for returning a Case to a queue.
SELECT tasks.*, task_timers.last_submitted_at as timer_will_trigger
FROM tasks INNER JOIN task_timers ON task_timers.task_id = tasks.id
WHERE tasks.type IN ('TimedHoldTask') AND tasks.status = 'assigned'
ORDER BY tasks.assigned_at
