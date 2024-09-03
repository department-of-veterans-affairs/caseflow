# frozen_string_literal: true

class Events::DecisionReviewUpdated
  class << self
    def update!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]
      reference_id = params[:reference_id]

      ActiveRecord::Base.transaction do
        event = find_or_create_event(consumer_event_id)
        # Update the Event after all backfills have completed
        event.update!(completed_at: Time.now.in_time_zone, error: nil, info: {})

        # loop through and update request issues
        request_issues.each do |request_issue|
          DecisionReviewUpdatedAudit.new(event: event, request_issue: request_issue, update_type: update_type).call
        end
      end
    end
  end
end
