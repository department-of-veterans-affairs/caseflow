# frozen_string_literal: true

class RequestIssuesCompleteEvent
  def initialize(review:, user:, parser:, event:, epe:)
    @event = event
    @parser = parser
    @review = review
    @epe = epe
  end
end
