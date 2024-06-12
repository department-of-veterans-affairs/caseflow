# frozen_string_literal: true

require_relative "../exceptions/standard_error"

class ApplicationJob < ActiveJob::Base
  class InvalidJobPriority < StandardError; end
  DELETE_SQS_MESSAGE_BEFORE_START = true

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

    # For jobs that run multiple times in a short time span, we do not want to continually update
    # the JobsExecutionTime table. This boolean will help us ignore those jobs
    def ignore_job_execution_time?
      false
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

  # Testing America/New_York TZ for all jobs in UAT.
  # :nocov:
  if Rails.deploy_env?(:uat)
    around_perform do |_job, block|
      Time.use_zone(Rails.configuration.time_zone) do
        block.call
      end
    end
  end
  # :nocov:

  before_perform do
    if self.class.app_name.present?
      RequestStore.store[:application] = "#{self.class.app_name}_job"
    end

    # Check whether Job execution time should be tracked
    unless self.class.ignore_job_execution_time?
      # Add Record to JobExecutionTimes to track the current job execution time
      JobExecutionTime.upsert(
        { job_name: self.class.to_s,
          last_executed_at: Time.now.utc },
        unique_by: :job_name
      )
    end
  end
end
