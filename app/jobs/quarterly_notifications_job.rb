# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :va_notify

  QUERY_LIMIT = ENV["QUARTERLY_NOTIFICATIONS_JOB_BATCH_SIZE"]

  NOTIFICATION_TYPES = Constants.QUARTERLY_STATUSES.to_h.tap do |types|
    types.delete(:quarterly_notification)
  end

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: SendNotificationJob queued to send_notification SQS queue
  def perform
    ensure_current_user_is_set

    begin
      NOTIFICATION_TYPES.each_key do |notification_type|
        jobs = AppealState.eligible_for_quarterly.send(notification_type).pluck(:appeal_id, :appeal_type)
          .map do |entry|
          NotificationInitializationJob.new(
            appeal_id: entry.first,
            appeal_type: entry.last,
            template_name: "Quarterly Notification",
            appeal_status: notification_type.to_s
          )
        end

        Parallel.each(jobs.each_slice(10).to_a, in_threads: 5) { |jobs_to_enqueue| enqueue_init_jobs(jobs_to_enqueue) }
      end
    rescue StandardError => error
      log_error(error)
    end
  end

  private

  # Batches enqueueing of the NotificationInitializationJobs in order to reduce round-trips to the SQS API
  #
  # @param jobs [Array<NotificationInitializationJob>] An array of NotificationInitializationJob objects to enqueue.
  #
  # @return [Aws::SQS::Types::SendMessageBatchResult]
  #   A struct containing the messages that were successfully enqueued and those that failed.
  def enqueue_init_jobs(jobs)
    CaseflowJob.enqueue_batch_of_jobs(
      jobs_to_enqueue: jobs,
      name_of_queue: NotificationInitializationJob.queue_name
    )
  end
end
