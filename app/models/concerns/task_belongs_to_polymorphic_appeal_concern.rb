# frozen_string_literal: true

module TaskBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  included do
    scope :ama, -> { where(appeal_type: "Appeal") }
    scope :legacy, -> { where(appeal_type: "LegacyAppeal") }
    scope :supplemental_claim, -> { where(appeal_type: "SupplementalClaim") }
    scope :higher_level_review, -> { where(appeal_type: "HigherLevelReview") }

    #===================================================================================================================
    # polymorphic 'appeal'-related associations
    #-------------------------------------------------------------------------------------------------------------------

    belongs_to :appeal, polymorphic: true

    # ------------------------------------------------------------------------------------------------------------------

    # Association for `joins` on ama_appeal (eg. `Task.joins(:ama_appeal)`)
    belongs_to :ama_appeal,
               -> { where(tasks: { appeal_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "appeal_id", optional: true

    # Association for querying ama_appeal on an individual Task (eg. `@some_task.ama_appeal`)
    belongs_to :ama_appeal_for_record,
               class_name: "Appeal", foreign_key: "appeal_id", optional: true
    private :ama_appeal_for_record, :ama_appeal_for_record=

    def ama_appeal
      ama_appeal_for_record if appeal_type == "Appeal"
    end

    # ------------------------------------------------------------------------------------------------------------------

    # Association for `joins` on legacy_appeal (eg. `Task.joins(:legacy_appeal)`)
    belongs_to :legacy_appeal,
               -> { where(tasks: { appeal_type: "LegacyAppeal" }) },
               class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true

    # Association for querying legacy_appeal on an individual Task (eg. `@some_task.legacy_appeal`)
    belongs_to :legacy_appeal_for_record,
               class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true
    private :legacy_appeal_for_record, :legacy_appeal_for_record=

    def legacy_appeal
      legacy_appeal_for_record if appeal_type == "LegacyAppeal"
    end

    #---------------------------------------------------------------------------------------------------------------------

    # Association for `joins` on supplemental_claim (eg. `Task.joins(:supplemental_claim)`)
    belongs_to :supplemental_claim,
               -> { where(tasks: { appeal_type: "SupplementalClaim" }) },
               class_name: "SupplementalClaim", foreign_key: "appeal_id", optional: true

    # Association for querying supplemental_claim on an individual Task (eg. `@some_task.supplemental_claim`)
    belongs_to :supplemental_claim_for_record,
               class_name: "SupplementalClaim", foreign_key: "appeal_id", optional: true
    private :supplemental_claim_for_record, :supplemental_claim_for_record=

    def supplemental_claim
      supplemental_claim_for_record if appeal_type == "SupplementalClaim"
    end

    #---------------------------------------------------------------------------------------------------------------------

    # Association for `joins` on higher_level_review (eg. `Task.joins(:higher_level_review)`)
    belongs_to :higher_level_review,
               -> { where(tasks: { appeal_type: "HigherLevelReview" }) },
               class_name: "HigherLevelReview", foreign_key: "appeal_id", optional: true

    # Association for querying higher_level_review on an individual Task (eg. `@some_task.higher_level_review`)
    belongs_to :higher_level_review_for_record,
               class_name: "HigherLevelReview", foreign_key: "appeal_id", optional: true
    private :higher_level_review_for_record, :higher_level_review_for_record=

    def higher_level_review
      higher_level_review_for_record if appeal_type == "HigherLevelReview"
    end

    #===================================================================================================================
  end
end
