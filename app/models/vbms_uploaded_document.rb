# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  include VbmsUploadedDocumentBelongsToPolymorphicAppealConcern

  has_many :vbms_communication_packages, as: :document_mailable_via_pacman

  validates :document_type, presence: true

  attribute :file, :string

  scope :successfully_uploaded, lambda {
    where(error: nil)
      .where.not(uploaded_to_vbms_at: nil)
      .where.not(attempted_at: nil)
      .where.not(processed_at: nil)
  }

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end
