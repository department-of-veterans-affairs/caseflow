VaBoxService = Rails.deploy_env?(:test) ? Fakes::VaBoxService : ExternalApi::VaBoxService
