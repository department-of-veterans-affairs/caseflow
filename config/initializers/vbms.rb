VBMSService = (!ApplicationController.dependencies_faked? ? ExternalApi::VBMSService : Fakes::VBMSService)

if ApplicationController.dependencies_faked?
  VBMSService.manifest_vbms_fetched_at = Time.zone.now
  VBMSService.manifest_vva_fetched_at = Time.zone.now
end