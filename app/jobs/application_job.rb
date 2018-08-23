class ApplicationJob < ActiveJob::Base
  def self.application_attr(app_name)
    @app_name = app_name
  end

  before_perform do
    # setup debug context
    Raven.extra_context(application: @app_name.to_s)
  end
end
