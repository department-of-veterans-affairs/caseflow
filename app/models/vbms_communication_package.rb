# frozen_string_literal: true
class VbmsCommunicationPackage < CaseflowRecord
  has_one :vbms_uploaded_document
  has_many :vbms_distributions
end
