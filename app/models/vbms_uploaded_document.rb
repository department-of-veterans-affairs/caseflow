# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  validates :document_type, presence: true

  attribute :file, :string

  # rubocop:disable Layout/LineLength
  scope :successfully_uploaded, -> { where(error: nil).where.not(uploaded_to_vbms_at: nil, attempted_at: nil, processed_at: nil) }
  # rubocop:enable Layout/LineLength

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end
