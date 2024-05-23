# frozen_string_literal: true

class TranscriptionPackage < CaseflowRecord
  validates :returned_at, presence: true
end
