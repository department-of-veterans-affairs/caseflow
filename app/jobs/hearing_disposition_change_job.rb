# frozen_string_literal: true

require "action_view"

class HearingDispositionChangeJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_as :low_priority

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
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

    # This is inefficient. If it runs slowly or consumes a lot of resources then refactor. Until then we're fine.
    tasks = DispositionTask.active.where.not(status: Constants.TASK_STATUSES.on_hold).select do |t|
      t.hearing && (t.hearing.scheduled_for < 24.hours.ago)
    end
    hearing_ids = tasks.map { |t| t.hearing.id }

    tasks.each do |task|
      hearing = task.hearing
      case hearing.disposition
      when Constants.HEARING_DISPOSITION_TYPES.held
        # Will be added as part of #9540. Ignoring this situation for now.
        task_count_for[hearing.disposition] += 1
      when Constants.HEARING_DISPOSITION_TYPES.cancelled
        task.cancel!
        task_count_for[hearing.disposition] += 1
      when Constants.HEARING_DISPOSITION_TYPES.postponed
        # Postponed hearings should be acted on immediately and the related tasks should be closed. Do not take any
        # action here.
        task_count_for[hearing.disposition] += 1
      when Constants.HEARING_DISPOSITION_TYPES.no_show
        task.mark_no_show!
        task_count_for[hearing.disposition] += 1
      when nil
        # We allow judges and hearings staff 2 days to make changes to the hearing's disposition. If it has been more
        # than 2 days since the hearing was held and there is no disposition then remind the hearings staff.
        if hearing.scheduled_for < 48.hours.ago
          # Logic will be added as part of #9833.
          task_count_for[:stale] += 1
        else
          task_count_for[:more_than_24_hours_old] += 1
        end
      else
        # Expect to never reach this block since all dispositions should be accounted for above. If we run into this
        # case we ignore it and will investigate and potentially incorporate that fix here. Until then we're fine.
        task_count_for[:unknown_dispositions] += 1
      end

    rescue StandardError => e
      # Rescue from errors so we attempt to change disposition even if we hit individual errors.
      Raven.capture_exception(e, extra: { task_id: task.id })
      error_count += 1
    end

    log_info(start_time, task_count_for, error_count, hearing_ids)
  rescue StandardError => e
    log_info(start_time, task_count_for, error_count, hearing_ids, e)
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

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
