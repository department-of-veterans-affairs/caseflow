class ApplicationJob < ActiveJob::Base
  class << self
    def application_attr(app_name)
      @app_name = app_name
    end

    attr_reader :app_name
  end

  around_perform do |job, block|
    # setup debug context
    Raven.tags_context(job: job.class.name, queue: job.queue_name)
    Raven.extra_context(application: self.class.app_name.to_s)
    if self.class.app_name.present?
      RequestStore.store[:application] = "#{self.class.app_name}_job"
    end

    block.call

    Raven::Context.clear!
  end
end
