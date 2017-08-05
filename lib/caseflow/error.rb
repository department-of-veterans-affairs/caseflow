module Caseflow::Error
  class DocumentRetrievalError < StandardError; end
  class MultipleAppealsByVBMSID < StandardError; end
  class CertificationMissingData < StandardError; end
  class InvalidSSN < StandardError; end
  class InvalidFileNumber < StandardError; end
end
