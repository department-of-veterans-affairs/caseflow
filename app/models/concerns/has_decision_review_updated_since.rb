# frozen_string_literal: true

module HasDecisionReviewUpdatedSince
  extend ActiveSupport::Concern

  included do
    scope :updated_since_for_appeals, lambda { |since|
      select(:decision_review_id)
        .where("#{table_name}.updated_at >= ?", since)
        .where("#{table_name}.decision_review_type='Appeal'")
    }
  end
end
