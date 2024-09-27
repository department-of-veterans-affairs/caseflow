Rails.application.config.to_prepare do
  BGSService = (!ApplicationController.dependencies_faked? ? ExternalApi::BGSService : Fakes::BGSService)
end
