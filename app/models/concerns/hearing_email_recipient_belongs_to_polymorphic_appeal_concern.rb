# frozen_string_literal: true

module HearingEmailRecipientBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :hearing_email_recipients, %w[Appeal LegacyAppeal])
  end
end
