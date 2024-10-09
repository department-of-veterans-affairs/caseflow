# frozen_string_literal: true

class Events::DecisionReviewUpdated
  class << self
    # rubocop: disable Metrics/MethodLength
    def update!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]
      ActiveRecord::Base.transaction do
        parser = Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new(headers, payload)

        user = Events::CreateUserOnEvent.handle_user_creation_on_event(event: event, css_id: parser.css_id,
                                                                       station_id: parser.station_id)

        review = EndProductEstablishment.find_by(
          reference_id: parser.end_product_establishments_reference_id
        )&.source

        RequestIssuesUpdateEvent.new(user: user, review: review, parser: parser).perform!

        event = find_or_create_event(consumer_event_id)

        Events::DecisionReviewUpdated::UpdateInformalConference.process!(event: event, parser: parser)
        Events::DecisionReviewUpdated::UpdateClaimReview.process!(event: event, parser: parser)

        # Update the Event after all operations have completed
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
    # rubocop: enable Metrics/MethodLength
  end
end
