Rails.application.config.to_prepare do
  PexipService = (!ApplicationController.dependencies_faked? ? ExternalApi::PexipService : Fakes::PexipService)
end
