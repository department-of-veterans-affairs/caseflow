Rails.application.config.to_prepare do
  PacmanService = (ApplicationController.dependencies_faked? ? Fakes::PacmanService : ExternalApi::PacmanService)
end
