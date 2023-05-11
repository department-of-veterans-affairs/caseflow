# frozen_string_literal: true
class VbmsCommunicationPackage < CaseflowRecord
  # Changed this association to "belongs_to" instead of "has_one" because FK sits on this table. Is that correct?
  #   – I also set to optional false, requiring the assocation to an existing vbms_uploaded_document. Is that correct?
  belongs_to :vbms_uploaded_document, optional: false
  # has_one :vbms_uploaded_document
  has_many :vbms_distributions

  validates :file_number, :comm_package_name, :document_referenced, presence: true

  # PacMan docs suggested multiline ^ and $ anchors for regex, but I changed to \A and \Z as suggested by rails log
  validates :comm_package_name, format: { with: /\A[\w !*+,-.:;=?]{1,225}\Z/ }

  # document_referenced has current data type of array of bigint values
  #   - if you try and store object with "id" and "copies" keys into db it will be converted to nil object
  #   - need to solve before being able to validate "id" and "copies"
  validates :document_referenced, length: { minimum: 1 }

  # This validation currently takes place in PrepareDocumentUploadToVbms... any reason it would need to take place again in model?
  validate :file_number_matches_bgs

  def bgs_service
    @bgs_service || BGSService.new
  end

  def file_number_matches_bgs
    if bgs_service.fetch_veteran_info(file_number).nil?
      errors.add(:file_number, "does not match a valid veteran file number")
    end
  end
end
