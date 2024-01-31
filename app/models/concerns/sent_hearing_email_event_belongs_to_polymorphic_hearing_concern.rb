# frozen_string_literal: true

module SentHearingEmailEventBelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :hearing, polymorphic: true

    belongs_to :ama_hearing,
               -> { includes(:email_events).where(sent_hearing_email_events: { hearing_type: "Hearing" }) },
               class_name: "Hearing", foreign_key: "hearing_id", optional: true

    def ama_hearing
      # `super()` will call the method created by the `belongs_to` above
      super() if hearing_type == "Hearing"
    end

    belongs_to :legacy_hearing,
               -> { includes(:email_events).where(sent_hearing_email_events: { hearing_type: "LegacyHearing" }) },
               class_name: "LegacyHearing", foreign_key: "hearing_id", optional: true

    def legacy_hearing
      # `super()` will call the method created by the `belongs_to` above
      super() if hearing_type == "LegacyHearing"
    end

    scope :ama, -> { where(hearing_type: "Hearing") }
    scope :legacy, -> { where(hearing_type: "LegacyHearing") }
  end
end
