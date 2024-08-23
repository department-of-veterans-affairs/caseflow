Rails.application.config.after_initialize do
  PexipService = (!ApplicationController.dependencies_faked? ? ExternalApi::PexipService : Fakes::PexipService)
end
