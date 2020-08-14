# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  include HasAppealUpdatedSince

  belongs_to :appeal, polymorphic: true
  validates :document_type, presence: true

  attribute :file, :string

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end
