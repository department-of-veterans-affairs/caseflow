Rails.application.config.after_initialize do
  BGSService = (!ApplicationController.dependencies_faked? ? ExternalApi::BGSService : Fakes::BGSService)
end
