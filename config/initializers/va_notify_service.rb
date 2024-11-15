Rails.application.config.to_prepare do
  case Rails.deploy_env
  when :uat, :prod
    VANotifyService = ExternalApi::VANotifyService
  else
    VANotifyService = Fakes::VANotifyService
  end
end
