# frozen_string_literal: true

class Transcription < CaseflowRecord
  belongs_to :hearing
  belongs_to :transcription_contractor
end
