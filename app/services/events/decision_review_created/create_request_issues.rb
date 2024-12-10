# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create Request Issues
# when an Event is received using the data sent from VBMS
class Events::DecisionReviewCreated::CreateRequestIssues
  class << self
    def process!(params)
      create_request_issue_backfill(params)
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedRequestIssuesError, error.message
    end

    private

    # iterate through the array of issues and create backfill object from each one
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def create_request_issue_backfill(params)
      event = params[:event]
      epe = params[:epe]
      parser = params[:parser]
      decision_review = params[:decision_review]
      request_issues = parser.request_issues
      newly_created_issues = []

      request_issues&.each do |issue|
        # create backfill RI object using extracted values
        parser_issues = Events::DecisionReviewCreated::DecisionReviewCreatedIssueParser.new(issue)

        if parser_issues.ri_reference_id.nil?
          fail Caseflow::Error::DecisionReviewCreatedRequestIssuesError, "reference_id cannot be null"
        end

        ri = RequestIssue.create!(
          reference_id: parser_issues.ri_reference_id,
          benefit_type: parser_issues.ri_benefit_type,
          contested_issue_description: parser_issues.ri_contested_issue_description,
          contention_reference_id: parser_issues.ri_contention_reference_id,
          contested_rating_decision_reference_id: parser_issues.ri_contested_rating_decision_reference_id,
          contested_rating_issue_profile_date: parser_issues.ri_contested_rating_issue_profile_date,
          contested_rating_issue_reference_id: parser_issues.ri_contested_rating_issue_reference_id,
          contested_decision_issue_id: parser_issues.ri_contested_decision_issue_id,
          decision_date: parser_issues.ri_decision_date,
          ineligible_due_to_id: parser_issues.ri_ineligible_due_to_id,
          ineligible_reason: parser_issues.ri_ineligible_reason,
          is_unidentified: parser_issues.ri_is_unidentified,
          unidentified_issue_text: parser_issues.ri_unidentified_issue_text,
          nonrating_issue_category: parser_issues.ri_nonrating_issue_category,
          nonrating_issue_description: parser_issues.ri_nonrating_issue_description,
          untimely_exemption: parser_issues.ri_untimely_exemption,
          untimely_exemption_notes: parser_issues.ri_untimely_exemption_notes,
          vacols_id: parser_issues.ri_vacols_id,
          vacols_sequence_id: parser_issues.ri_vacols_sequence_id,
          closed_at: parser_issues.ri_closed_at,
          closed_status: parser_issues.ri_closed_status,
          contested_rating_issue_diagnostic_code: parser_issues.ri_contested_rating_issue_diagnostic_code,
          ramp_claim_id: parser_issues.ri_ramp_claim_id,
          rating_issue_associated_at: parser_issues.ri_rating_issue_associated_at,
          nonrating_issue_bgs_id: parser_issues.ri_nonrating_issue_bgs_id,
          nonrating_issue_bgs_source: parser_issues.ri_nonrating_issue_bgs_source,
          end_product_establishment_id: epe.id,
          veteran_participant_id: parser.veteran_participant_id,
          decision_review: decision_review,
          remand_source_id: parser_issues.ri_remand_source_id
        )
        create_event_record(event, ri)
        newly_created_issues.push(ri)

        # LegacyIssue (only for non Remands)
        if vacols_ids_exist?(ri) && ri.remand_source_id.blank?
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
      EventRecord.create!(
        event: event,
        evented_record: issue,
        info: { update_type: "I", record_data: issue }
      )
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
      vacols_issue = vacols_issue(request_issue.vacols_id, request_issue.vacols_sequence_id)
      optin = LegacyIssueOptin.create!(
        request_issue: request_issue,
        original_disposition_code: vacols_issue.disposition_id,
        original_disposition_date: vacols_issue.disposition_date,
        legacy_issue: legacy_issue,
        original_legacy_appeal_decision_date: vacols_issue&.legacy_appeal&.decision_date,
        original_legacy_appeal_disposition_code: vacols_issue&.legacy_appeal&.case_record&.bfdc,
        folder_decision_date: vacols_issue&.legacy_appeal&.case_record&.folder&.tidcls
      )
      create_event_record(event, optin)
    end

    def vacols_issue(vacols_id, vacols_sequence_id)
      AppealRepository.issues(vacols_id).find do |issue|
        issue.vacols_sequence_id == vacols_sequence_id
      end
    end
  end
end
