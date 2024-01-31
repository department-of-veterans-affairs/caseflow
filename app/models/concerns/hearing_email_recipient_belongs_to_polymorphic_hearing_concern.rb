# frozen_string_literal: true

module HearingEmailRecipientBelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :hearing, polymorphic: true

    belongs_to :ama_hearing,
               -> { includes(:email_recipients).where(hearing_email_recipients: { hearing_type: "Hearing" }) },
               class_name: "Hearing", foreign_key: "hearing_id", optional: true

    belongs_to :legacy_hearing,
               -> { includes(:email_recipients).where(hearing_email_recipients: { hearing_type: "LegacyHearing" }) },
               class_name: "LegacyHearing", foreign_key: "hearing_id", optional: true
  end
end
