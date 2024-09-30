# frozen_string_literal: true

module TaskBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper
  include DecisionReviewPolymorphicSTIHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :tasks)
    define_polymorphic_decision_review_sti_associations(:appeal, :tasks)
  end
end
