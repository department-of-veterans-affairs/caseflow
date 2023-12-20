# frozen_string_literal: true

require_relative "../exceptions/standard_error"

class ApplicationJob < ActiveJob::Base
  class InvalidJobPriority < StandardError; end

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
  end
end
