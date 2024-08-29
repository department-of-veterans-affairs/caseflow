# frozen_string_literal: true

class CaseflowJob < ApplicationJob
  attr_accessor :start_time

  before_perform do |job|
    job.start_time = Time.zone.now
  end

  # Note: This block is not called if an error occurs when `perform` is executed --
  # see https://stackoverflow.com/questions/50263787/does-active-job-call-after-perform-when-perform-raises-an-error
  after_perform do |job|
    metrics_service_report_runtime(metric_group_name: job.class.name.underscore) unless @reported_to_metrics_service
  end

  class << self
    # Serializes and formats a job object so that it can be placed into an SQS message queue
    #
    # @param job [ActiveJob::Base] The job to be serialized
    #
    # @return [Hash]
    #   A hash representation of the job object that is compatible with SQS.
    def serialize_job_for_enqueueing(job)
      ActiveJob::QueueAdapters::ShoryukenAdapter.instance.send(:message, job)
    end

    # Allows for enqueueing up to 10 async jobs at a time via the SendMessageBatch endpoint in the
    #   SQS API. This is to allow for reducing the number of round trips to the API when enqueueing a large
    #   number of jobs for delayed execution.
    #
    # @param jobs_to_enqueue [Array<ActiveJob::Base>] The jobs to enqueue for later execution.
    # @param name_of_queue [String] The name of the SQS queue to place the messages onto.
    #
    # @return [Aws::SQS::Types::SendMessageBatchResult]
    #   A struct containing the messages that were successfully enqueued and those that failed.
    def enqueue_batch_of_jobs(jobs_to_enqueue:, name_of_queue:)
      fail Caseflow::Error::MaximumBatchSizeViolationError if jobs_to_enqueue.size > 10

      Shoryuken::Client.queues(name_of_queue).send_messages(
        jobs_to_enqueue.map { serialize_job_for_enqueueing(_1) }
      )
    end
  end

  def metrics_service_report_runtime(metric_group_name:)
    MetricsService.record_runtime(
      app_name: "caseflow_job",
      metric_group: metric_group_name,
      start_time: @start_time
    )
    @reported_to_metrics_service = true
  end

  def metrics_service_report_time_segment(segment:, start_time:)
    job_duration_seconds = Time.zone.now - start_time

    MetricsService.emit_gauge(
      app_name: "caseflow_job_segment",
      metric_group: segment,
      metric_name: "runtime",
      metric_value: job_duration_seconds
    )
  end

  def slack_service
    @slack_service ||= SlackService.new
  end

  def log_error(error, extra: {})
    Rails.logger.error(error)
    Rails.logger.error(error.backtrace.join("\n"))
    capture_exception(error: error, extra: extra)
  end
end
