# frozen_string_literal: true

class TaskTimerJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_as :low_priority
  application_attr :queue

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = TaskTimerJob.name.underscore

  #  grab task type and appeal from tasks

  def perform
    datadog_service(app_name: APP_NAME, metric_group_name: METRIC_GROUP_NAME).set_job_start_time
    start_time = Time.zone.now
    RequestStore.store[:current_user] = User.system_user

    TaskTimer.requires_processing.each do |task_timer|
      # TODO: if this job's runtime gets too long, spawn individual jobs for each task timer.
      process(task_timer)
    end

    TaskTimer.requires_cancelling.each do |task_timer|
      cancel(task_timer)
    end

    datadog_service.report_runtime
  end

  private

  def process(task_timer)
    # Calling ".with_lock" will block the current thread until
    # no other threads have a lock on the row, and will reload
    # the record after acquiring the lock.
    task_timer.with_lock do
      task_timer.attempted!
      task_timer.task.when_timer_ends
      task_timer.clear_error!
      task_timer.processed!
    end
  rescue StandardError => error
    # Ensure errors are sent to Sentry, but don't block the job from continuing.
    # The next time the job runs, we'll process the unprocessed task timers again.
    task_timer.update_error!(error.inspect)
    capture_exception(error: error)
  end

  def cancel(task_timer)
    task_timer.with_lock do
      task_timer.canceled!
    end
  rescue StandardError => error
    # Ensure errors are sent to Sentry, but don't block the job from continuing.
    # The next time the job runs, we'll process the unprocessed task timers again.
    task_timer.update_error!(error.inspect)
    capture_exception(error: error)
  end
end
