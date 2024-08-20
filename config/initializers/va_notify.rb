environment_fakes = Fakes::VANotifyService

if Rails.deploy_env?(:prodtest)
  VANotifyService = environment_fakes
else
  VANotifyService = (ApplicationController.dependencies_faked? ? environment_fakes : ExternalApi::VANotifyService)
end
