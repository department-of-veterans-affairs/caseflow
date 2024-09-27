# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  class InvalidJobPriority < StandardError; end

  # Override in job classes if you anticipate that the job will take longer than the SQS visibility
  # timeout value (ex: currently 5 hours for our low priority queue at the time of writing this)
  # to prevent multiple instances of the job from being executed.
  #
  # See https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
  DELETE_SQS_MESSAGE_BEFORE_START = false

  # For jobs that run multiple times in a short time span, we do not want to continually update
  # the JobsExecutionTime table. This boolean will help us ignore those jobs
  IGNORE_JOB_EXECUTION_TIME = false

  class << self
    def queue_with_priority(priority)
      unless [:low_priority, :high_priority].include? priority
        fail InvalidJobPriority, "#{priority} is not a valid job priority!"
      end

      queue_as priority
    end

    def application_attr(app_name)
      @app_name = app_name
    end

    attr_reader :app_name
  end

  rescue_from Caseflow::Error::TransientError, VBMS::ClientError, BGS::ShareError do |error|
    capture_exception(error: error)
  end

  def capture_exception(error:, extra: {})
    if error.ignorable?
      Rails.logger.error(error)
    else
      Raven.capture_exception(error, extra: extra)
    end
  end

  before_perform do
    if self.class.app_name.present?
      RequestStore.store[:application] = "#{self.class.app_name}_job"
    end

    # Check whether Job execution time should be tracked
    unless self.class::IGNORE_JOB_EXECUTION_TIME
      # Add Record to JobExecutionTimes to track the current job execution time
      JobExecutionTime.upsert(
        { job_name: self.class.to_s,
          last_executed_at: Time.now.utc },
        unique_by: :job_name
      )
    end
  end
end
