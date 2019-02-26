require "action_view"

class UpdateAppellantRepresentationJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_as :low_priority

  def perform
    start_time = Time.zone.now
    new_task_count = 0
    closed_task_count = 0
    error_count = 0

    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    Appeal.active.each do |a|
      appeal_new_task_count, appeal_closed_task_count = a.sync_tracking_tasks
      new_task_count += appeal_new_task_count
      closed_task_count += appeal_closed_task_count

      # TODO: Add an alert if we've been running for longer than x number of minutes?
    rescue StandardError => e
      # Rescue from errors when looping over appeals so that we attempt to sync tracking tasks for each appeal.
      Raven.capture_exception(e, extra: { appeal_id: a.id })
      error_count += 1
    end

    log_info(start_time, new_task_count, closed_task_count, error_count)
  rescue StandardError => e
    log_info(start_time, new_task_count, closed_task_count, error_count, e)
  end

  def log_info(start_time, new_task_count, closed_task_count, error_count, err = nil)
    duration = time_ago_in_words(start_time)
    result = err ? "failed" : "completed"
    msg = "UpdateAppellantRepresentationJob #{result} after running for #{duration}." \
          " Created #{new_task_count} new tracking tasks and closed #{closed_task_count} existing tracking tasks." \
          " Encountered errors for #{error_count} individual appeals."

    msg += " Fatal error: #{err.message}" if err
    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n")) if err
    slack_service.send_notification(msg)
  end
end
