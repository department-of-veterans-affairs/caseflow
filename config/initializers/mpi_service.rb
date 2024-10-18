Rails.application.config.to_prepare do
  MPIService = (!ApplicationController.dependencies_faked? ? ExternalApi::MPIService : Fakes::MPIService)
end
