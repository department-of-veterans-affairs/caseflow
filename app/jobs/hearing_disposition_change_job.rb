# frozen_string_literal: true

require "action_view"

class HearingDispositionChangeJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_as :low_priority

  # rubocop:disable Metrics/MethodLength
  def perform
    start_time = Time.zone.now
    error_count = 0
    task_count_for = {
      Constants.HEARING_DISPOSITION_TYPES.held => 0,
      Constants.HEARING_DISPOSITION_TYPES.cancelled => 0,
      Constants.HEARING_DISPOSITION_TYPES.postponed => 0,
      Constants.HEARING_DISPOSITION_TYPES.no_show => 0,
      more_than_24_hours_old: 0,
      stale: 0,
      unknown_dispositions: 0
    }

    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    tasks = eligible_disposition_tasks
    hearing_ids = tasks.map { |t| t.hearing.id }

    tasks.each do |task|
      label = modify_task_by_dispisition(task)
      task_count_for[label] += 1
    rescue StandardError => e
      # Rescue from errors so we attempt to change disposition even if we hit individual errors.
      Raven.capture_exception(e, extra: { task_id: task.id })
      error_count += 1
    end

    log_info(start_time, task_count_for, error_count, hearing_ids)
  rescue StandardError => e
    log_info(start_time, task_count_for, error_count, hearing_ids, e)
  end
  # rubocop:enable Metrics/MethodLength

  def eligible_disposition_tasks
    # This is inefficient. If it runs slowly or consumes a lot of resources then refactor. Until then we're fine.
    DispositionTask.active.where.not(status: Constants.TASK_STATUSES.on_hold).select do |t|
      t.hearing && (t.hearing.scheduled_for < 24.hours.ago)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def modify_task_by_dispisition(task)
    hearing = task.hearing
    label = hearing.disposition

    # rubocop:disable Lint/EmptyWhen
    case hearing.disposition
    when Constants.HEARING_DISPOSITION_TYPES.held
      # Will be added as part of #9540. Ignoring this situation for now.
    when Constants.HEARING_DISPOSITION_TYPES.cancelled
      task.cancel!
    when Constants.HEARING_DISPOSITION_TYPES.postponed
      # Postponed hearings should be acted on immediately and the related tasks should be closed. Do not take any
      # action here.
    when Constants.HEARING_DISPOSITION_TYPES.no_show
      task.mark_no_show!
    when nil
      # We allow judges and hearings staff 2 days to make changes to the hearing's disposition. If it has been more
      # than 2 days since the hearing was held and there is no disposition then remind the hearings staff.
      label = if hearing.scheduled_for < 48.hours.ago
                # Logic will be added as part of #9833.
                :stale
              else
                :more_than_24_hours_old
              end
    else
      # Expect to never reach this block since all dispositions should be accounted for above. If we run into this
      # case we ignore it and will investigate and potentially incorporate that fix here. Until then we're fine.
      label = :unknown_dispositions
    end
    # rubocop:enable Lint/EmptyWhen

    label
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def log_info(start_time, task_count_for, error_count, hearing_ids, err = nil)
    duration = time_ago_in_words(start_time)
    result = err ? "failed" : "completed"

    msg = "#{self.class.name} #{result} after running for #{duration}."
    task_count_for.keys.each do |k, v|
      msg += "Processed #{v} #{k.to_s.humanize} hearings"
    end
    msg += " Encountered errors for #{error_count} hearings."
    msg += " Fatal error: #{err.message}" if err

    Rails.logger.info(msg)
    Rails.logger.info(hearing_ids)
    Rails.logger.info(err.backtrace.join("\n")) if err

    slack_service.send_notification(msg)
  end
end
