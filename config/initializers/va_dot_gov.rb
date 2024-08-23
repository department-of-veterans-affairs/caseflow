Rails.application.config.after_initialize do
  VADotGovService = (ApplicationController.dependencies_faked? ? Fakes::VADotGovService : ExternalApi::VADotGovService)
end
