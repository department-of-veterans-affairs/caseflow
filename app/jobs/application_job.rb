# frozen_string_literal: true

require_relative "../exceptions/standard_error"

class ApplicationJob < ActiveJob::Base
  class << self
    def application_attr(app_name)
      @app_name = app_name
    end

    attr_reader :app_name
  end

  rescue_from VBMS::ClientError, BGS::ShareError do |error|
    capture_exception(error: error)
  end

  def capture_exception(error:, extra: {})
    if error.ignorable?
      Rails.logger.error(error)
    else
      Raven.capture_exception(error, extra: extra)
    end
  end

  before_perform do |job|
    # setup debug context
    Raven.tags_context(job: job.class.name, queue: job.queue_name)
    Raven.extra_context(application: self.class.app_name.to_s)
    if self.class.app_name.present?
      RequestStore.store[:application] = "#{self.class.app_name}_job"
    end
  end
end
