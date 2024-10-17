# frozen_string_literal: true

module SentHearingEmailEventBelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :hearing, polymorphic: true

    belongs_to :ama_hearing,
               -> { where(sent_hearing_email_events: { hearing_type: "Hearing" }) },
               class_name: "Hearing", foreign_key: "hearing_id", optional: true

    belongs_to :legacy_hearing,
               -> { where(sent_hearing_email_events: { hearing_type: "LegacyHearing" }) },
               class_name: "LegacyHearing", foreign_key: "hearing_id", optional: true

    scope :ama, -> { where(hearing_type: "Hearing") }
    scope :legacy, -> { where(hearing_type: "LegacyHearing") }
  end
end
