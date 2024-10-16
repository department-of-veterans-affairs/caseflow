# frozen_string_literal: true

module TaskBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper
  include DecisionReviewPolymorphicSTIHelper

  included do
    belongs_to :appeal, polymorphic: true

    belongs_to :ama_appeal,
               -> { where(tasks: { appeal_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "appeal_id", optional: true

    belongs_to :legacy_appeal,
               -> { where(tasks: { appeal_type: "LegacyAppeal" }) },
               class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true

    belongs_to :higher_level_review,
               -> { where(tasks: { appeal_type: "HigherLevelReview" }) },
               class_name: "HigherLevelReview", foreign_key: "appeal_id", optional: true

    belongs_to :supplemental_claim,
               -> { where(tasks: { appeal_type: "SupplementalClaim" }) },
               class_name: "SupplementalClaim", foreign_key: "appeal_id", optional: true

    belongs_to :correspondence,
               -> { where(tasks: { appeal_type: "Correspondence" }) },
               class_name: "Correspondence", foreign_key: "appeal_id", optional: true

    scope :ama, -> { where(appeal_type: "Appeal") }
    scope :legacy, -> { where(appeal_type: "LegacyAppeal") }
    scope :higher_level_review, -> { where(appeal_type: "HigherLevelReview") }
    scope :supplemental_claim, -> { where(appeal_type: "SupplementalClaim") }
    scope :correspondence, -> { where(appeal_type: "Correspondence") }
    define_polymorphic_decision_review_associations(:appeal, :tasks)
    define_polymorphic_decision_review_sti_associations(:appeal, :tasks)
  end
end
