class VbmsCommunicationPackage < CaseflowRecord

  belongs_to :vbms_uploaded_documents
  has_many :vbms_distributions

end
