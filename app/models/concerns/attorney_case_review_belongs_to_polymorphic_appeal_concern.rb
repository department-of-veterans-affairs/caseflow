# frozen_string_literal: true

module AttorneyCaseReviewBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :appeal, polymorphic: true

    belongs_to :ama_appeal,
               -> { includes(:attorney_case_reviews).where(attorney_case_reviews: { appeal_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "appeal_id", optional: true

    belongs_to :legacy_appeal,
               -> { includes(:attorney_case_reviews).where(attorney_case_reviews: { appeal_type: "LegacyAppeal" }) },
               class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true

    scope :ama, -> { where(appeal_type: "Appeal") }
    scope :legacy, -> { where(appeal_type: "LegacyAppeal") }
  end
end
