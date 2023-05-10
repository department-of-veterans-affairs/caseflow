# frozen_string_literal: true
class VbmsCommunicationPackage < CaseflowRecord
  has_one :vbms_uploaded_document
  has_many :vbms_distributions

  validates :file_number, :comm_package_name, :document_referenced, presence: true

  # Would this validation already happen/be more appropriate in the PacMan controller?
  validate :file_number_matches_bgs

  # PacMan docs suggested multiline ^ and $ anchors for regex, but I changed to \A and \Z as suggested by rails log
  validates :comm_package_name, format: { with: /\A[\w !*+,-.:;=?]{1,225}\Z/ }

  # document_referenced has current data type of array of bigint values
  #   - if you try and store object with "id" and "copies" keys into db it will be converted to nil object
  #   - need to solve before being able to validate "id" and "copies"
  validates :document_referenced, length: { minimum: 1 }

  def bgs_service
    @bgs_service || BGSService.new
  end

  def file_number_matches_bgs
    if bgs_service.fetch_veteran_info(file_number).nil?
      errors.add(:file_number, "does not match a valid veteran file number")
    end
  end
end
