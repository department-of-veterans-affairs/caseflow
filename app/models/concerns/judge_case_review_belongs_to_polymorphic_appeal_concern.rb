# frozen_string_literal: true

module JudgeCaseReviewBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :judge_case_reviews, %w[Appeal LegacyAppeal])
  end
end
