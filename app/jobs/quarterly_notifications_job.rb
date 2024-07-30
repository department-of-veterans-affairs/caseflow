# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  include MessageConfigurations::DeleteMessageBeforeStart

  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :va_notify

  NOTIFICATION_TYPES = Constants.QUARTERLY_STATUSES.to_h.freeze

  # Locates appeals eligible for quarterly notifications and queues a NotificationInitializationJob
  # for each for further processing, and eventual (maybe) transmission of correspondence to an appellant.
  #
  # @return [Hash]
  #   Returns the hash of NOTIFICATION_TYPES that were iterated over, though this value isn't designed
  #     to be utilized by a caller due to the async nature of this job.
  def perform
    ensure_current_user_is_set

    begin
      NOTIFICATION_TYPES.each_key do |notification_type|
        status_text = NOTIFICATION_TYPES[notification_type.to_sym]

        jobs = AppealState.eligible_for_quarterly.send(notification_type).pluck(:appeal_id, :appeal_type)
          .map do |related_appeal_info|
          NotificationInitializationJob.new(
            appeal_id: related_appeal_info.first,
            appeal_type: related_appeal_info.last,
            template_name: Constants.EVENT_TYPE_FILTERS.quarterly_notification,
            appeal_status: status_text
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
