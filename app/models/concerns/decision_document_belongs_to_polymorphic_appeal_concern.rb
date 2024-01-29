# frozen_string_literal: true

module DecisionDocumentBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :appeal, polymorphic: true

    belongs_to :ama_appeal,
               -> { includes(:decision_documents).where(decision_documents: { appeal_type: "Appeal" }) },
               class_name: "Appeal", foreign_key: "appeal_id", optional: true

    def ama_appeal
      # `super()` will call the method created by the `belongs_to` above
      super() if appeal_type == "Appeal"
    end

    belongs_to :legacy_appeal,
               -> { includes(:decision_documents).where(decision_documents: { appeal_type: "LegacyAppeal" }) },
               class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true

    def legacy_appeal
      # `super()` will call the method created by the `belongs_to` above
      super() if appeal_type == "LegacyAppeal"
    end

    scope :ama, -> { where(appeal_type: "Appeal") }
    scope :legacy, -> { where(appeal_type: "LegacyAppeal") }
  end
end
