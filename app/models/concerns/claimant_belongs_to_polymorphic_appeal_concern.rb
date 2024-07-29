# frozen_string_literal: true

module ClaimantBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:decision_review, :claimants)
  end
end
