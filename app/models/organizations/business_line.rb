# frozen_string_literal: true

class BusinessLine < Organization
  include DecisionReviewTasksConcern

  def tasks_url
    "/decision_reviews/#{url}"
  end
end
