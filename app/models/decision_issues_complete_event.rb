# frozen_string_literal: true

class DecisionIssuesCompleteEvent
  def initialize(review:, user:, parser:, event:, epe:)
    @event = event
    @parser = parser
    @review = review
    @epe = epe
    @user = user
  end
end
