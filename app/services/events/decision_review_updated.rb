# frozen_string_literal: true

class Events::DecisionReviewUpdated
  class << self
    def update!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]

      ActiveRecord::Base.transaction do
        event = find_or_create_event(consumer_event_id)
        # Update the Event after all backfills have completed
        event.update!(completed_at: Time.now.in_time_zone, error: nil, info: {})

        request_issues.each do |request_issue|
          if request_issue.updated_at > request_issue.created_at
            DecisionReviewUpdatedAudit.new(event: event, request_issue: request_issue, update_type: "U").call
          elsif request_issue.destroyed?
            DecisionReviewUpdatedAudit.new(event: event, request_issue: request_issue, update_type: "D").call
          end
        end
      end
    end
  end
end