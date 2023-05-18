# frozen_string_literal: true

class VbmsCommunicationPackage < CaseflowRecord
  belongs_to :vbms_uploaded_document, optional: false
  has_many :vbms_distributions

  validates :file_number, :comm_package_name, :copies, presence: true
  validates :comm_package_name, length: { in: 1..255 }, format: { with: /\A[\w !*+,-.:;=?]{1,255}\Z/ }
  validates :copies, length: { in: 1..500 }
end
