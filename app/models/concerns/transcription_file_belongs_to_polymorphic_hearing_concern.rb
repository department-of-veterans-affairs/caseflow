# frozen_string_literal: true

module TranscriptionFileBelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :hearing, polymorphic: true

    belongs_to :ama_hearing,
               -> { where(transcription_files: { hearing_type: "Hearing" }) },
               class_name: "Hearing", foreign_key: "hearing_id", optional: true

    belongs_to :legacy_hearing,
               -> { where(transcription_files: { hearing_type: "LegacyHearing" }) },
               class_name: "LegacyHearing", foreign_key: "hearing_id", optional: true

    scope :ama, -> { where(hearing_type: "Hearing") }
    scope :legacy, -> { where(hearing_type: "LegacyHearing") }
  end
end
