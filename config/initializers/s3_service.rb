Rails.application.config.to_prepare do
  require 'caseflow'

  S3Service = (Rails.application.config.s3_enabled ? Caseflow::S3Service : Caseflow::Fakes::S3Service)
end
