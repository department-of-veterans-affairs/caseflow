# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  belongs_to :appeal, optional: false
  validates :document_type, presence: true

  attribute :file, :string

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end
