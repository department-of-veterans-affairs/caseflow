# frozen_string_literal: true
class VbmsCommunicationPackage < CaseflowRecord
  has_one :vbms_uploaded_document
  has_many :vbms_distributions

  validates :file_number, :comm_package_name, :document_referenced, presence: true

  # file_number format can be validated with bgs_service.fetch_verteran_info(file_number)
  #   – Would this validation be more appropriate in PacMan controller and not here?

  # PacMan docs suggested multiline ^ and $ anchors for regex, but I changed to \A and \Z as suggested by rails log
  validates :comm_package_name, format: { with: /\A[\w !*+,-.:;=?]{1,225}\Z/ }

  # document_referenced has current data type of array of bigint values
  #   - if you try and store object with "id" and "copies" keys into db it will be converted to nil object
  #   - need to solve before being able to validate "id" and "copies"
  validates :document_referenced, length: { minimum: 1 }
end
