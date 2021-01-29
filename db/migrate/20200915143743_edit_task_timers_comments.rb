class EditTaskTimersComments < Caseflow::Migration
  def up
    change_table_comment :task_timers, "A task timer allows an associated task's (like EvidenceSubmissionWindowTask and TimedHoldTask) `when_timer_ends` method to be run asynchronously after timer expires."
    change_column_comment :task_timers, :attempted_at, "Async timestamp for most recent attempt to run Task#when_timer_ends."
    change_column_comment :task_timers, :canceled_at, "Timestamp when job was abandoned. Associated task is typically cancelled."
    change_column_comment :task_timers, :last_submitted_at, "Async timestamp for most recent job start. Initially set to when timer should expire (Task#timer_ends_at)."
    change_column_comment :task_timers, :processed_at, "Async timestamp for when the job completes successfully. Associated task's method Task#when_timer_ends ran successfully."
    change_column_comment :task_timers, :task_id, "ID of the associated Task to be run."
  end
  def down
    change_table_comment :task_timers, "Task timers allow tasks to be run asynchronously after some future date, like EvidenceSubmissionWindowTask."
    change_column_comment :task_timers, :attempted_at, "Async timestamp for most recent attempt to run."
    change_column_comment :task_timers, :canceled_at, "Timestamp when job was abandoned"
    change_column_comment :task_timers, :last_submitted_at, "Async timestamp for most recent job start."
    change_column_comment :task_timers, :processed_at, "Async timestamp for when the job completes successfully."
    change_column_comment :task_timers, :task_id, "ID of the Task to be run."
  end
end
