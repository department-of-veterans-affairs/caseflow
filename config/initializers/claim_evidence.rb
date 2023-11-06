ClaimEvidenceService = if ApplicationController.dependencies_faked?
                        Fakes::ClaimEvidenceService
                       else
                        ExternalApi::ClaimEvidenceService
                       end
