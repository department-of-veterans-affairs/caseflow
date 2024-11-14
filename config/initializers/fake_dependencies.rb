Rails.application.config.after_initialize do
  Fakes::Initializer.app_init!(Rails.env)
end
