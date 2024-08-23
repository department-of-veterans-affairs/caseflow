Rails.application.config.after_initialize do
  MPIService = (!ApplicationController.dependencies_faked? ? ExternalApi::MPIService : Fakes::MPIService)
end
