# frozen_string_literal: true
class VbmsCommunicationPackage < CaseflowRecord
  belongs_to :vbms_uploaded_document
  has_many :vbms_distributions
end
