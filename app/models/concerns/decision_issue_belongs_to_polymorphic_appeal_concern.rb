# frozen_string_literal: true

module DecisionIssueBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :decision_review, polymorphic: true

    belongs_to :ama_appeal,
               -> { where(decision_issues: { decision_review_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "decision_review_id", optional: true

    belongs_to :higher_level_review,
               -> { where(decision_issues: { decision_review_type: "HigherLevelReview" }) },
               class_name: "HigherLevelReview", foreign_key: "decision_review_id", optional: true

    belongs_to :supplemental_claim,
               -> { where(decision_issues: { decision_review_type: "SupplementalClaim" }) },
               class_name: "SupplementalClaim", foreign_key: "decision_review_id", optional: true

    scope :ama, -> { where(decision_review_type: "Appeal") }
    scope :higher_level_review, -> { where(decision_review_type: "HigherLevelReview") }
    scope :supplemental_claim, -> { where(decision_review_type: "SupplementalClaim") }
  end
end
