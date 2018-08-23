class ApplicationJob < ActiveJob::Base
  class << self
    def application_attr(app_name)
      @app_name = app_name
    end
    
    attr_reader :app_name
  end

  before_perform do
    # setup debug context
    Raven.extra_context(application: self.class.app_name.to_s)
  end
end
