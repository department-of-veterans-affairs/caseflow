Rails.application.config.to_prepare do
  GovDeliveryService = if ApplicationController.dependencies_faked?
                         Fakes::GovDeliveryService
                       else
                         ExternalApi::GovDeliveryService
                       end
end
