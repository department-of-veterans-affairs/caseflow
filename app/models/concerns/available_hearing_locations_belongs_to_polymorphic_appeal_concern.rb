# frozen_string_literal: true

module AvailableHearingLocationsBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :available_hearing_locations, %w[Appeal LegacyAppeal])
  end
end
