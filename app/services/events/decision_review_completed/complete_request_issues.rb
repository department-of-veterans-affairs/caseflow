# frozen_string_literal: true

# Service class to handle completion of RequestIssues and creating DecisionIssues
class Events::DecisionReviewCompleted::CompleteRequestIssues
  class << self
    def process!(params)
      process_request_issues(params)
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCompletedRequestIssueError, error.message
    end

    private

    # iterate through the array of completed_issues and create DecisionIssues from each one
    def process_request_issues(params)
      event = params[:event]
      parser = params[:parser]
      claim_review = params[:review]
      completed_request_issues = []
      request_issues_to_complete = parser.completed_issues

      request_issues_to_complete&.each do |issue|
        # create backfill RI object using extracted values
        parser_issue = Events::DecisionReviewCompleted::DecisionReviewCompletedIssueParser.new(issue)

        if parser_issue.ri_reference_id.nil?
          fail Caseflow::Error::DecisionReviewCompletedRequestIssuesError, "reference_id cannot be null"
        end

        # fetch existing RequestIssue in CF
        ri = RequestIssue.find(parser_issue.ri_reference_id)

        # TODO: update all RI fields; RequestIssueUpdate model needed?
        # TODO: create new EventRecord(s) for each RI to show an update was performed

        # create DI backfill and associated Records
        create_decision_issue_backfill(issue, ri)
      end
    end

    def create_decision_issue_backfill(issue_param, request_issue)
      di = DecisionIssue.create!(
        benefit_type: issue_param.decision_issue_benefit_type,
        contention_reference_id: issue_param.decision_issue_contention_reference_id,
        decision_text: issue_param.decision_issue_decision_text,
        description: issue_param.decision_issue_description,
        diagnostic_code: issue_param.decision_issue_diagnostic_code,
        disposition: issue_param.decision_issue_disposition,
        end_product_last_action_date: issue_param.decision_issue_end_product_last_action_date,
        participant_id: issue_param.decision_issue_participant_id,
        percent_number: issue_param.decision_issue_percent_number,
        rating_issue_reference_id: issue_param.decision_issue_rating_issue_reference_id,
        rating_profile_date: issue_param.decision_issue_rating_profile_date,
        rating_promulgation_date: issue_param.decision_issue_rating_promulgation_date,
        subject_text: issue_param.decision_issue_subject_text
      )

      # create RequestDecisionIssue to link the DI with the RI
      RequestDecisionIssue.create!(decision_issue: di, request_issue: request_issue)

      # create EventRecords
      EventRecord.create!(
        event: event,
        evented_record: di
      )
    end
  end
end
