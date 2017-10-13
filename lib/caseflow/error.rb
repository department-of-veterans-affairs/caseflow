module Caseflow::Error
  class DocumentRetrievalError < StandardError; end
  class MultipleAppealsByVBMSID < StandardError; end
  class CertificationMissingData < StandardError; end
  class InvalidSSN < StandardError; end
  class InvalidFileNumber < StandardError; end
  class InvalidVBMSId < StandardError; end
  class MustImplementInSubclass < StandardError; end
end
