# frozen_string_literal: true

class DocumentView < CaseflowRecord
  belongs_to :document
  belongs_to :user
end
