GovDeliveryService = if ApplicationController.dependencies_faked?
                       Fakes::GovDeliveryService
                     else
                       ExternalApi::GovDeliveryService
                     end
