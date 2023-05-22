# frozen_string_literal: true

class VbmsCommunicationPackage < CaseflowRecord
  belongs_to :vbms_uploaded_document, optional: false
  has_many :vbms_distributions

  with_options presence: true do
    validates :file_number
    validates :comm_package_name, length: { in: 1..255 }, format: { with: /\A[\w !*+,-.:;=?]{1,255}\Z/ }
    validates :copies, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 500 }
  end
end
