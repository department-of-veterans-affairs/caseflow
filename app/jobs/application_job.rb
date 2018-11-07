class ApplicationJob < ActiveJob::Base
  class << self
    def application_attr(app_name)
      @app_name = app_name
    end

    attr_reader :app_name
  end

  before_perform do |job|
    # setup debug context
    Raven.tags_context(job: job.class.name, queue: job.queue_name)
    Raven.extra_context(application: self.class.app_name.to_s)
  end
end
