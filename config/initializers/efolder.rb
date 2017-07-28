# Fakes::VBMSService provides the same functionality as a Fakes::EfolderService would. We can refactor
# this later when we switch Caseflow to read all documents from efolder permanently

# If you're in a development or test environment and want to use the EfolderService, just set the environment variable
# EFOLDER_EXPRESS_URL
EFolderService = FeatureToggle.enabled?(:efolder_docs_api) ? ExternalApi::EfolderService : Fakes::VBMSService
