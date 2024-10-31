Rails.application.config.to_prepare do
  WebexService = (ApplicationController.dependencies_faked? ? Fakes::WebexService : ExternalApi::WebexService)
end
