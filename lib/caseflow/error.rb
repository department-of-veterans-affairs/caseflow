module Caseflow::Error
  class DocumentRetrievalError < StandardError; end
  class MultipleAppealsByVBMSID < StandardError; end
  class CertificationMissingData < StandardError; end
  class InvalidSSN < StandardError; end
  class InvalidFileNumber < StandardError; end
  class MustImplementInSubclass < StandardError; end
  class AttributeNotLoaded < StandardError; end

  class EstablishClaimFailedInVBMS < StandardError
    attr_reader :error_code

    def initialize(error_code)
      @error_code = error_code
    end

    def self.from_vbms_error(error)
      case error.body
      when /PIF is already in use/
        new("duplicate_ep")
      when /A duplicate claim for this EP code already exists/
        new("duplicate_ep")
      when /The PersonalInfo SSN must not be empty./
        new("missing_ssn")
      when /The PersonalInfo.+must not be empty/
        new("bgs_info_invalid")
      else
        error
      end
    end
  end
end
