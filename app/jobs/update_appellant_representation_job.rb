# frozen_string_literal: true

require "action_view"

class UpdateAppellantRepresentationJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_with_priority :low_priority
  application_attr :queue

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = UpdateAppellantRepresentationJob.name.underscore
  TOTAL_NUMBER_OF_APPEALS_TO_UPDATE = 1000

  def perform
    start_time = Time.zone.now

    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    appeals_to_update.each do |appeal|
      sync_record = appeal.record_synced_by_job.find_or_create_by(sync_job_name: UpdateAppellantRepresentationJob.name)

      new_task_count, closed_task_count = TrackVeteranTask.sync_tracking_tasks(appeal)
      sync_record.update!(processed_at: Time.zone.now)

      increment_task_count("new", appeal.id, new_task_count)
      increment_task_count("closed", appeal.id, closed_task_count)

      # TODO: Add an alert if we've been running for longer than x number of minutes?
    rescue StandardError => error
      # Rescue from errors when looping over appeals so that we attempt to sync tracking tasks for each appeal.
      capture_exception(error: error, extra: { appeal_id: appeal.id })
      increment_task_count("error", appeal.id)
    end

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  rescue StandardError => error
    log_error(start_time, error)
  end

  def appeals_to_update
    number_to_update = retrieve_number_to_update

    legacy_appeals = RecordSyncedByJob.next_records_to_process(
      legacy_appeals_with_hearings,
      number_to_update[:number_of_legacy_appeals_to_update]
    )
    appeals = RecordSyncedByJob.next_records_to_process(
      active_appeals,
      number_to_update[:number_of_appeals_to_update]
    )

    [legacy_appeals, appeals].flatten
  end

  def retrieve_number_to_update
    number_of_legacy_appeals = legacy_appeals_with_hearings.size
    number_of_ama_appeals = active_appeals.size

    {
      number_of_legacy_appeals_to_update:
        TOTAL_NUMBER_OF_APPEALS_TO_UPDATE * number_of_legacy_appeals /
          (number_of_legacy_appeals + number_of_ama_appeals),
      number_of_appeals_to_update:
        TOTAL_NUMBER_OF_APPEALS_TO_UPDATE * number_of_ama_appeals /
          (number_of_legacy_appeals + number_of_ama_appeals)
    }
  end

  def legacy_appeals_with_hearings
    LegacyAppeal.joins(:tasks).where(
      "tasks.type = ? AND tasks.status NOT IN (?)", "AssignHearingDispositionTask", Task.closed_statuses
    )
  end

  def active_appeals
    Appeal.joins(:tasks).where("tasks.type = ? AND tasks.status NOT IN (?)", "RootTask", Task.closed_statuses)
  end

  def increment_task_count(task_effect, appeal_id, count = 1)
    count.times do
      DataDogService.increment_counter(
        app_name: APP_NAME,
        metric_group: METRIC_GROUP_NAME,
        metric_name: "tasks",
        attrs: {
          effect: task_effect,
          appeal_id: appeal_id
        }
      )
    end
  end

  def log_error(start_time, err)
    duration = time_ago_in_words(start_time)
    msg = "UpdateAppellantRepresentationJob failed after running for #{duration}. Fatal error: #{err.message}"

    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err)

    slack_service.send_notification("[ERROR] #{msg}", self.class.to_s)

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end
end
