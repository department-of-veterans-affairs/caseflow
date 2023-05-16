# frozen_string_literal: true
class VbmsCommunicationPackage < CaseflowRecord
  belongs_to :vbms_uploaded_document, optional: false
  has_many :vbms_distributions

  validates :file_number, :comm_package_name, :document_referenced, presence: true
  validates :comm_package_name, length: { in: 1..255 }, format: { with: /\A[\w !*+,-.:;=?]{1,255}\Z/ }

  validates :document_referenced, length: { minimum: 1 }
  #   - document_referenced has current data type of array of bigint values
  #   - need to change before being able to validate nested values of "id" and "copies"
end
