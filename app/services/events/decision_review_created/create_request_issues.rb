# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create Request Issues
# when an Event is received using the data sent from VBMS
class Events::DecisionReviewCreated::CreateRequestIssues
  class << self
    def process!(event:, parser:, epe:, decision_review:)
      create_request_issue_backfill(event, parser, epe, decision_review)
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedRequestIssuesError, error.message
    end

    private

    # iterate through the array of issues and create backfill object from each one
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def create_request_issue_backfill(event, parser, epe, decision_review)
      request_issues = parser.request_issues
      newly_created_issues = []

      request_issues&.each do |issue|
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
          nonrating_issue_bgs_source: parser.ri_nonrating_issue_bgs_source(issue),
          end_product_establishment_id: epe.id,
          veteran_participant_id: parser.veteran_participant_id,
          decision_review: decision_review
        )
        create_event_record(event, ri)
        newly_created_issues.push(ri)

        # LegacyIssue
        if vacols_ids_exist?(ri)
          legacy_issue = create_legacy_issue_backfill(event, ri)

          # LegacyIssueOptin
          if optin?(decision_review) && ri.ineligible_reason.blank?
            create_legacy_optin_backfill(event, ri, legacy_issue)
          end
        end
      end
      newly_created_issues
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def create_event_record(event, issue)
      EventRecord.create!(event: event, evented_record: issue)
    end

    # Legacy issue checks
    def vacols_ids_exist?(request_issue)
      request_issue.vacols_id.present? && request_issue.vacols_sequence_id.present?
    end

    def optin?(decision_review)
      decision_review.legacy_opt_in_approved?
    end

    def create_legacy_issue_backfill(event, request_issue)
      li = LegacyIssue.create!(request_issue_id: request_issue.id,
                               vacols_id: request_issue.vacols_id,
                               vacols_sequence_id: request_issue.vacols_sequence_id)
      create_event_record(event, li)

      li
    end

    def create_legacy_optin_backfill(event, request_issue, legacy_issue)
      optin = LegacyIssueOptin.create!(request_issue_id: request_issue.id,
                                       legacy_issue: legacy_issue)
      create_event_record(event, optin)
    end
  end
end
