# frozen_string_literal: true

module DecisionDocumentBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :decision_documents, %w[Appeal LegacyAppeal])
  end
end
