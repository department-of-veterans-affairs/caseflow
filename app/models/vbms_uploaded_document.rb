# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  include HasSimpleAppealUpdatedSince

  belongs_to :appeal, optional: false
  validates :document_type, presence: true

  before_create :temporarily_set_appeal_type

  attribute :file, :string

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end

  private

  def temporarily_set_appeal_type
    self.appeal_type = Appeal.name
  end
end
