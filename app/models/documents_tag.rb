# frozen_string_literal: true

class DocumentsTag < CaseflowRecord
  belongs_to :document
  belongs_to :tag

  has_paper_trail save_changes: false, on: [:update, :destroy]
end
