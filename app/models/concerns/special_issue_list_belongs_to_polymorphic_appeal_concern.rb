# frozen_string_literal: true

module SpecialIssueListBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :special_issue_lists, %w[Appeal LegacyAppeal])
  end
end
