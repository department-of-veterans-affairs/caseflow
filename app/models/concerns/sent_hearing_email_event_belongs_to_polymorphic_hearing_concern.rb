# frozen_string_literal: true

module SentHearingEmailEventBelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:hearing, :sent_hearing_email_events, %w[Hearing LegacyHearing])
  end
end
