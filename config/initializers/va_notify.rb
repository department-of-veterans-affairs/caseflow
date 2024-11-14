case Rails.deploy_env
when :uat, :prod
  VANotifyService = ExternalApi::VANotifyService
else
  VANotifyService = Fakes::VANotifyService
end
