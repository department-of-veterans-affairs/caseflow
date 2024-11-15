Rails.application.config.to_prepare do
  EFolderService =
    if !ApplicationController.dependencies_faked? || Rails.application.config.use_efolder_locally
      ExternalApi::EfolderService
    else
      Fakes::VBMSService
    end
end
