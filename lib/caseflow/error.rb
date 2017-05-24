module Caseflow::Error
  class MultipleAppealsByVBMSID < StandardError; end
  class CertificationMissingData < StandardError; end
end
