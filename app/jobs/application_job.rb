class ApplicationJob < ActiveJob::Base
  class << self
    def application_attr(app_name)
      @app_name = app_name
    end

    attr_reader :app_name
  end

  around_perform do |job, block|
    block.call
  rescue StandardError => ex
    tags = { job: job.class.name, queue: job.queue_name }
    context = {
      job_id: job.job_id,
      queue_name: job.queue_name,
      job_class: job.class.name
    }
    Raven.capture_exception(ex, tags: tags, extra: context)
    raise
  end

  before_perform do
    # setup debug context
    Raven.extra_context(application: self.class.app_name.to_s)
  end
end
