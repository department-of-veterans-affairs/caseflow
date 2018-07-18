class ApplicationJob < ActiveJob::Base
  def self.application_attr(app_name)
    # setup debug context
    Raven.extra_context(application: app_name.to_s)
  end
end
