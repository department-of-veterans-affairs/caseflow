Rails.application.config.to_prepare do
  VBMSService = (!ApplicationController.dependencies_faked? ? ExternalApi::VBMSService : Fakes::VBMSService)

  if ApplicationController.dependencies_faked?
    VBMSService.manifest_vbms_fetched_at = VBMSService.manifest_vbms_fetched_at.try(:utc).try(:strftime, "%FT%T.%LZ")
    VBMSService.manifest_vva_fetched_at = VBMSService.manifest_vva_fetched_at.try(:utc).try(:strftime, "%FT%T.%LZ")
  end
end
