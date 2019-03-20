# frozen_string_literal: true

require "action_view"

class HearingDispositionChangeJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  def run
    @start_time = Time.zone.now

    tasks.each do |task|
      label = modify_task_by_dispisition(task)
      increment_task_count_for(label)
    rescue StandardError => error
      # Rescue from errors so we attempt to change disposition even if we hit individual errors.
      Raven.capture_exception(error, extra: { task_id: task.id })
      increment_errored_task_count
    end
  rescue StandardError => error
    @job_error = error
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def modify_task_by_dispisition(task)
    hearing = task.hearing
    label = hearing.disposition

    # rubocop:disable Lint/EmptyWhen
    case hearing.disposition
    when Constants.HEARING_DISPOSITION_TYPES.held
      task.hold!
    when Constants.HEARING_DISPOSITION_TYPES.cancelled
      task.cancel!
    when Constants.HEARING_DISPOSITION_TYPES.postponed
      # Postponed hearings should be acted on immediately and the related tasks should be closed. Do not take any
      # action here.
    when Constants.HEARING_DISPOSITION_TYPES.no_show
      task.no_show!
    when nil
      # We allow judges and hearings staff 2 days to make changes to the hearing's disposition. If it has been more
      # than 2 days since the hearing was held and there is no disposition then remind the hearings staff.
      label = if hearing.scheduled_for < 48.hours.ago
                # Logic will be added as part of #9833.
                :stale
              else
                :between_one_and_two_days_old
              end
    else
      # Expect to never reach this block since all dispositions should be accounted for above. If we run into this
      # case we ignore it and will investigate and potentially incorporate that fix here. Until then we're fine.
      label = :unknown_disposition
    end
    # rubocop:enable Lint/EmptyWhen

    label
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def publish_results
    msg = "HearingDispositionChangeJob #{result} after running for #{duration}. #{task_results_message}" \
          " Encountered errors for #{error_count} hearings. #{job_error_message}"

    Rails.logger.info(msg)
    Rails.logger.info(hearing_ids)
    Rails.logger.info(err.backtrace.join("\n")) if @job_error

    slack_service.send_notification(msg)
  end

  def duration
    time_ago_in_words(@start_time)
  end

  def job_error_message
    @job_error ? " Fatal error: #{err.message}" : ""
  end

  def result
    @job_error ? "failed" : "completed"
  end

  def tasks
    @tasks ||= DispositionTask.ready_for_action
  end

  def increment_errored_task_count
    @error_count ||= 0
    @error_count += 1
  end

  def task_results_message
    @task_count_for.map { |label, task_count| " Processed #{task_count} #{label.to_s.humanize} hearings." }.join
  end

  def increment_task_count_for(label)
    @task_count_for ||= {
      Constants.HEARING_DISPOSITION_TYPES.held => 0,
      Constants.HEARING_DISPOSITION_TYPES.cancelled => 0,
      Constants.HEARING_DISPOSITION_TYPES.postponed => 0,
      Constants.HEARING_DISPOSITION_TYPES.no_show => 0,
      between_one_and_two_days_old: 0,
      stale: 0,
      unknown_disposition: 0
    }

    @task_count_for[label] += 1
  end
end
