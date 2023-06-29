# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal

  has_many :vbms_communication_packages, as: :document

  validates :document_type, presence: true

  attribute :file, :string

  scope :successfully_uploaded, lambda {
    where(error: nil).where.not(uploaded_to_vbms_at: nil, attempted_at: nil, processed_at: nil)
  }

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end
