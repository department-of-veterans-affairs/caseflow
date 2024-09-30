# frozen_string_literal: true

class Events::DecisionReviewUpdated::DecisionReviewUpdatedAudit
  def initialize(event:, request_issue:, update_type:)
    @event = event
    @request_issue = request_issue
    @update_type = update_type
  end

  def call
    EventRecord.create!(
      event: @event,
      evented_record: @request_issue,
      info: { update_type: @update_type, record_data: @request_issue }
    )
  end
end
