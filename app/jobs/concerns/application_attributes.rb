# Allows for a developer to specify which ActiveJob belongs to which application
# This is used for proper debugging with sentry and other internal tools
module ApplicationAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def application_attr(app_name)
      # setup debug context
      Raven.extra_context(application: app_name)
    end
  end
end
