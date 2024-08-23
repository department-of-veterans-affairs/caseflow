Rails.application.config.after_initialize do
  PacmanService = (ApplicationController.dependencies_faked? ? Fakes::PacmanService : ExternalApi::PacmanService)
end
