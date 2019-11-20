# frozen_string_literal: true

require "action_view"

class HearingDispositionChangeJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    complete_hearing_disposition_tasks
    lock_hearing_days
  end

  def complete_hearing_disposition_tasks
    start_time = Time.zone.now
    error_count = 0
    hearing_ids = []

    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    hearing_disposition_tasks.each do |task|
      # Skip task unless there is a hearing associated with the task and it was held more than a day ago.
      next unless task&.hearing&.scheduled_for &.< 24.hours.ago

      hearing_ids.push(task.hearing.id)
      label = update_task_by_hearing_disposition(task)
      increment_task_count_for(label)
    rescue StandardError => error
      # Rescue from errors so we attempt to change disposition even if we hit individual errors.
      capture_exception(error: error, extra: { task_id: task.id })
      error_count += 1
    end

    log_info(start_time, task_count_for, error_count, hearing_ids)
  rescue StandardError => error
    log_info(start_time, task_count_for, error_count, hearing_ids, error)
  end

  def hearing_disposition_tasks
    Task.active.where(type: AssignHearingDispositionTask.name)
  end

  def task_count_for
    @task_count_keys ||= Constants.HEARING_DISPOSITION_TYPES.to_h.values.map(&:to_sym) +
                         [:between_one_and_two_days_old, :stale, :unknown_disposition]
    @task_count_for ||= Hash[@task_count_keys.map { |key| [key, 0] }]
  end

  def increment_task_count_for(label)
    task_count_for[label.to_sym] += 1
  end

  def update_task_by_hearing_disposition(task)
    label = disposition_label(task.hearing)

    case label
    when Constants.HEARING_DISPOSITION_TYPES.held
      task.hold!
    when Constants.HEARING_DISPOSITION_TYPES.cancelled
      task.cancel!
    when Constants.HEARING_DISPOSITION_TYPES.postponed
      task.postpone!
    when Constants.HEARING_DISPOSITION_TYPES.no_show
      task.no_show!
    when :stale
      # complete the AssignHearingDispositionTask and create a ChangeHearingDispositionTask to
      # remind staff to update the hearing's disposition
      task.parent.create_change_hearing_disposition_task
    end

    label
  end

  def disposition_label(hearing)
    if Constants.HEARING_DISPOSITION_TYPES.to_h.value?(hearing.disposition)
      hearing.disposition
    elsif hearing.disposition.nil?
      if hearing.scheduled_for < 48.hours.ago
        # stale if there's no disposition after 2 days
        :stale
      else
        :between_one_and_two_days_old
      end
    else
      # we should never reach this, but will investigate if we do
      :unknown_disposition
    end
  end

  def lock_hearing_days
    HearingDay
      .where("scheduled_for < ?", 1.day.ago.to_date)
      .where(lock: [false, nil])
      .update_all(lock: true)
  end

  def log_info(start_time, task_count_for, error_count, hearing_ids, err = nil)
    duration = time_ago_in_words(start_time)
    result = err ? "failed" : "completed"

    msg = "#{self.class.name} #{result} after running for #{duration}."
    task_count_for.each do |label, task_count|
      msg += " Processed #{task_count} #{label.to_s.humanize} hearings."
    end
    msg += " Encountered errors for #{error_count} hearings."
    msg += " Fatal error: #{err.message}" if err

    Rails.logger.info(msg)
    Rails.logger.info(hearing_ids)
    Rails.logger.info(err.backtrace.join("\n")) if err

    slack_service.send_notification(msg)
  end
end
