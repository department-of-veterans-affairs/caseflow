# frozen_string_literal: true

module AppealStateBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :appeal_states, %w[Appeal LegacyAppeal])
  end
end
