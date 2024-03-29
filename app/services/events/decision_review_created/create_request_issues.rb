# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create Request Issues
# when an Event is received using the data sent from VBMS
class Events::DecisionReviewCreated::CreateRequestIssues
  class << self
    def process!(event, parser, epe)
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
        # Extract values using .dig() method for each column
        # benefit_type = issue.dig(:benefit_type)
        benefit_type = parser.ri_benefit_type(issue)
        contested_issue_description = issue.dig(:contested_issue_description)
        contention_reference_id = issue.dig(:contention_reference_id)
        contested_rating_decision_reference_id = issue.dig(:contested_rating_decision_reference_id)
        contested_rating_issue_profile_date = issue.dig(:contested_rating_issue_profile_date)
        contested_rating_issue_reference_id = issue.dig(:contested_rating_issue_reference_id)
        contested_decision_issue_id = issue.dig(:contested_decision_issue_id)
        decision_date = issue.dig(:decision_date)
        ineligible_due_to_id = issue.dig(:ineligible_due_to_id)
        ineligible_reason = issue.dig(:ineligible_reason)
        is_unidentified = issue.dig(:is_unidentified)
        unidentified_issue_text = issue.dig(:unidentified_issue_text)
        nonrating_issue_category = issue.dig(:nonrating_issue_category)
        nonrating_issue_description = issue.dig(:nonrating_issue_description)
        untimely_exemption = issue.dig(:untimely_exemption)
        untimely_exemption_notes = issue.dig(:untimely_exemption_notes)
        vacols_id = issue.dig(:vacols_id)
        vacols_sequence_id = issue.dig(:vacols_sequence_id)
        closed_at = issue.dig(:closed_at)
        closed_status = issue.dig(:closed_status)
        contested_rating_issue_diagnostic_code = issue.dig(:contested_rating_issue_diagnostic_code)
        nonrating_issue_bgs_id = issue.dig(:nonrating_issue_bgs_id)

        # create backfill RI object using extracted values
        ri = RequestIssue.create!(
          benefit_type: benefit_type,
          contested_issue_description: contested_issue_description,
          contention_reference_id: contention_reference_id,
          contested_rating_decision_reference_id: contested_rating_decision_reference_id,
          contested_rating_issue_profile_date: contested_rating_issue_profile_date,
          contested_rating_issue_reference_id: contested_rating_issue_reference_id,
          contested_decision_issue_id: contested_decision_issue_id,
          decision_date: parser.logical_date_converter(decision_date),
          ineligible_due_to_id: ineligible_due_to_id,
          ineligible_reason: ineligible_reason,
          is_unidentified: is_unidentified,
          unidentified_issue_text: unidentified_issue_text,
          nonrating_issue_category: nonrating_issue_category,
          nonrating_issue_description: nonrating_issue_description,
          untimely_exemption: untimely_exemption,
          untimely_exemption_notes: untimely_exemption_notes,
          vacols_id: vacols_id,
          vacols_sequence_id: vacols_sequence_id,
          closed_at: closed_at,
          closed_status: closed_status,
          contested_rating_issue_diagnostic_code: contested_rating_issue_diagnostic_code,
          end_product_establishment_id: epe.id,
          nonrating_issue_bgs_id: nonrating_issue_bgs_id
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
