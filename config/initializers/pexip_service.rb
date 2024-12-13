Rails.application.config.to_prepare do
  PexipService = (ApplicationController.dependencies_faked? ? Fakes::PexipService : ExternalApi::PexipService)
end
