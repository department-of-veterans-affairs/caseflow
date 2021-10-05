# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  include HasAppealUpdatedSince

  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal

  validates :document_type, presence: true

  attribute :file, :string

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end
