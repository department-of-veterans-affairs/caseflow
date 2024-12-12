# frozen_string_literal: true

module CorrespondenceBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :correspondence, %w[Correspondence])
  end
end
