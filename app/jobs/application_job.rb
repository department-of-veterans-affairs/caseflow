class ApplicationJob < ActiveJob::Base
  def application_attr(app_name)
    # setup debug context
    Raven.extra_context(application: app_name)
  end
end
