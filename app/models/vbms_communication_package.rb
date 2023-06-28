# frozen_string_literal: true

class VbmsCommunicationPackage < CaseflowRecord
  belongs_to :vbms_uploaded_document, optional: false
  has_many :vbms_distributions

  validates :file_number, :comm_package_name, :copies, presence: true
  validates :comm_package_name, length: { in: 1..255 }, format: { with: /\A[\w !*+,-.:;=?]{1,255}\Z/ }
  validates :copies, numericality: { only_integer: true, greater_than: 0, less_than: 501 }
end
