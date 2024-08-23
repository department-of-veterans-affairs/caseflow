Rails.application.config.after_initialize do
  GovDeliveryService = if ApplicationController.dependencies_faked?
                         Fakes::GovDeliveryService
                       else
                         ExternalApi::GovDeliveryService
                       end
end
