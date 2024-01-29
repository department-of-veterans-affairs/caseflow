# frozen_string_literal: true

module DecisionIssueBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :decision_review, polymorphic: true

    belongs_to :ama_appeal,
               -> { includes(:decision_issues).where(decision_issues: { decision_review_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "decision_review_id", optional: true

    def ama_appeal
      # `super()` will call the method created by the `belongs_to` above
      super() if decision_review_type == "Appeal"
    end

    belongs_to :higher_level_review,
               -> { includes(:decision_issues).where(decision_issues: { decision_review_type: "HigherLevelReview" }) },
               class_name: "HigherLevelReview", foreign_key: "decision_review_id", optional: true

    def higher_level_review
      # `super()` will call the method created by the `belongs_to` above
      super() if decision_review_type == "HigherLevelReview"
    end

    belongs_to :supplemental_claim,
               -> { includes(:decision_issues).where(decision_issues: { decision_review_type: "SupplementalClaim" }) },
               class_name: "SupplementalClaim", foreign_key: "decision_review_id", optional: true

    def supplemental_claim
      # `super()` will call the method created by the `belongs_to` above
      super() if decision_review_type == "SupplementalClaim"
    end

    scope :ama, -> { where(decision_review_type: "Appeal") }
    scope :higher_level_review, -> { where(decision_review_type: "HigherLevelReview") }
    scope :supplemental_claim, -> { where(decision_review_type: "SupplementalClaim") }
  end
end
