# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create Request Issues
# when an Event is received using the data sent from VBMS
class Events::DecisionReviewCreated::CreateRequestIssues
  class << self
    def process!(event:, parser:, epe:)
      create_request_issue_backfill(event, parser, epe)
    rescue Caseflow::Error::DecisionReviewCreatedRequestIssuesError => error
      raise error
    end

    private

    # iterate through the array of issues and create backfill object from each one
    def create_request_issue_backfill(event, parser, epe)
      request_issues = parser.request_issues
      newly_created_issues = []

      request_issues.each do |issue|
        # create backfill RI object using extracted values
        ri = RequestIssue.create!(
          benefit_type: parser.ri_benefit_type(issue),
          contested_issue_description: parser.ri_contested_issue_description(issue),
          contention_reference_id: parser.ri_contention_reference_id(issue),
          contested_rating_decision_reference_id: parser.ri_contested_rating_decision_reference_id(issue),
          contested_rating_issue_profile_date: parser.ri_contested_rating_issue_profile_date(issue),
          contested_rating_issue_reference_id: parser.ri_contested_rating_issue_reference_id(issue),
          contested_decision_issue_id: parser.ri_contested_decision_issue_id(issue),
          decision_date: parser.ri_decision_date(issue),
          ineligible_due_to_id: parser.ri_ineligible_due_to_id(issue),
          ineligible_reason: parser.ri_ineligible_reason(issue),
          is_unidentified: parser.ri_is_unidentified(issue),
          unidentified_issue_text: parser.ri_unidentified_issue_text(issue),
          nonrating_issue_category: parser.ri_nonrating_issue_category(issue),
          nonrating_issue_description: parser.ri_nonrating_issue_description(issue),
          untimely_exemption: parser.ri_untimely_exemption(issue),
          untimely_exemption_notes: parser.ri_untimely_exemption_notes(issue),
          vacols_id: parser.ri_vacols_id(issue),
          vacols_sequence_id: parser.ri_vacols_sequence_id(issue),
          closed_at: parser.ri_closed_at(issue),
          closed_status: parser.ri_closed_status(issue),
          contested_rating_issue_diagnostic_code: parser.ri_contested_rating_issue_diagnostic_code(issue),
          ramp_claim_id: parser.ri_ramp_claim_id(issue),
          rating_issue_associated_at: parser.ri_rating_issue_associated_at(issue),
          nonrating_issue_bgs_id: parser.ri_nonrating_issue_bgs_id(issue),
          end_product_establishment_id: epe.id
        )
        create_request_issue_event_record(event, ri)
        newly_created_issues.push(ri)
      end
      newly_created_issues
    end

    def create_request_issue_event_record(event, issue)
      EventRecord.create!(event: event, backfill_record: issue)
    end
  end
end
