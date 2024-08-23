Rails.application.config.after_initialize do
  VANotifyService = (ApplicationController.dependencies_faked? ? Fakes::VANotifyService : ExternalApi::VANotifyService)
end
