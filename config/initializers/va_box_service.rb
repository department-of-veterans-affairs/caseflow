# config/initializers/va_box_service.rb

Rails.application.reloader.to_prepare do
  VaBoxService = Rails.deploy_env?(:test) ? Fakes::VaBoxService : ExternalApi::VaBoxService
end
