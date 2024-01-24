# frozen_string_literal: true

module TaskBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :appeal, polymorphic: true

    belongs_to :ama_appeal,
               -> { includes(:tasks).where(tasks: { appeal_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "appeal_id", optional: true

    def ama_appeal
      # `super()` will call the method created by the `belongs_to` above
      super() if appeal_type == "Appeal"
    end

    belongs_to :legacy_appeal,
               -> { includes(:tasks).where(tasks: { appeal_type: "LegacyAppeal" }) },
               class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true

    def legacy_appeal
      # `super()` will call the method created by the `belongs_to` above
      super() if appeal_type == "LegacyAppeal"
    end

    belongs_to :higher_level_review,
               -> { includes(:tasks).where(tasks: { appeal_type: "HigherLevelReview" }) },
               class_name: "HigherLevelReview", foreign_key: "appeal_id", optional: true

    def higher_level_review
      # `super()` will call the method created by the `belongs_to` above
      super() if appeal_type == "HigherLevelReview"
    end

    belongs_to :supplemental_claim,
               -> { includes(:tasks).where(tasks: { appeal_type: "SupplementalClaim" }) },
               class_name: "SupplementalClaim", foreign_key: "appeal_id", optional: true

    def supplemental_claim
      # `super()` will call the method created by the `belongs_to` above
      super() if appeal_type == "SupplementalClaim"
    end

    scope :ama, -> { where(appeal_type: "Appeal") }
    scope :legacy, -> { where(appeal_type: "LegacyAppeal") }
    scope :higher_level_review, -> { where(appeal_type: "HigherLevelReview") }
    scope :supplemental_claim, -> { where(appeal_type: "SupplementalClaim") }
  end
end
