# Fakes::VBMSService provides the same functionality as a Fakes::EfolderService would. We can refactor
# this later when we switch Caseflow to read all documents from efolder permanently
EFolderService = FeatureToggle.enabled?(:efolder_docs_api) ? ExternalApi::EfolderService : Fakes::VBMSService
