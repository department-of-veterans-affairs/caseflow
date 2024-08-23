Rails.application.config.to_prepare do
  VADotGovService = (ApplicationController.dependencies_faked? ? Fakes::VADotGovService : ExternalApi::VADotGovService)
end
