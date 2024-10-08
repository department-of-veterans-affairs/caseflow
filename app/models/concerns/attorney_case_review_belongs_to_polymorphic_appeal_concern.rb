# frozen_string_literal: true

module AttorneyCaseReviewBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :attorney_case_reviews, %w[Appeal LegacyAppeal])
  end
end
