class TaskTimerComments < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:task_timers, "Task timers allow tasks to be run asynchronously after some future date, like EvidenceSubmissionWindowTask.")
    change_column_comment(:task_timers, :attempted_at, "Async timestamp for most recent attempt to run.")
    change_column_comment(:task_timers, :created_at, "Automatic timestamp for record creation.")
    change_column_comment(:task_timers, :error, "Async any error message from most recent failed attempt to run.")
    change_column_comment(:task_timers, :last_submitted_at, "Async timestamp for most recent job start.")
    change_column_comment(:task_timers, :processed_at, "Async timestamp for when the job completes successfully.")
    change_column_comment(:task_timers, :submitted_at, "Async timestamp for initial job start.")
    change_column_comment(:task_timers, :task_id, "ID of the Task to be run.")
    change_column_comment(:task_timers, :updated_at, "Automatic timestmap for record update.")
  end
end
