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

        jobs.in_groups_of(10) { |jobs_to_enqueue| enqueue_batch_of_jobs(jobs_to_enqueue.compact) }
      end
    rescue StandardError => error
      log_error(error)
    end
  end

  private

  # Shoryuken::Client.sqs.get_queue_attributes(queue_url: Shoryuken::Client.queues(self.queue_name).url)

  def serialize_job_for_enqueueing(job)
    ActiveJob::QueueAdapters::ShoryukenAdapter.instance.send(:message, job)
  end

  # TODO: Allow for queue_name param, and make sure all jobs are configured to
  # go onto that queue normally.
  def enqueue_batch_of_jobs(jobs_to_enqueue)
    fail StandardError, "Number of jobs must not exceed 10" if jobs_to_enqueue.size > 10

    Shoryuken::Client.queues(queue_name).send_messages(
      jobs_to_enqueue.map { |job| serialize_job_for_enqueueing(job) }
    )
  end
end
