# frozen_string_literal: true

module DecisionIssueBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:decision_review,
                                                    :decision_issues,
                                                    %w[Appeal HigherLevelReview SupplementalClaim])
  end
end
