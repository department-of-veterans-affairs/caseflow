# frozen_string_literal: true

# This class is used to update request issues for a decision review based on event data
# The event data is parsed into an object that is in the same format as an intake dataset from the UI
# The base class is used to update the request issues and calculate the before and after issues
# This class is used to update the request issues with the event data and process additional updates
# that are specific to event updates

# Special logic is needed for exisiting issues that are not included in the event data
# but need to be part of the data sent to the base class to ensure
# the correct before and after issues are calculated
class RequestIssuesUpdateEvent < RequestIssuesUpdate
  def initialize(review:, user:, parser:, event:, epe:)
    @event = event
    @parser = parser
    @review = review
    @epe = epe
    # build_request_issues_data
    super(
      user: user,
      review: review,
      request_issues_data: []
    )
  end

  # rubocop:disable Metrics/MethodLength
  def perform!
    process_eligible_to_ineligible_issues!
    process_ineligible_to_eligible_issues!
    process_ineligible_to_ineligible_issues!

    before_request_issues = before_issues || []
    newly_created_issues = create_request_issue_backfill || []
    newly_updated_issues = process_updated_issues! || []
    newly_withdrawn_issues = process_withdrawn_issues! || []
    newly_removed_issues = update_removed_issues! || []

    process_legacy_issues!

    after_issues = (before_request_issues + newly_created_issues - newly_removed_issues).uniq
    update!(
      before_request_issue_ids: before_request_issues.map(&:id),
      after_request_issue_ids: after_issues.map(&:id),
      withdrawn_request_issue_ids: newly_withdrawn_issues.map(&:id),
      edited_request_issue_ids: newly_updated_issues.map(&:id),
      mst_edited_request_issue_ids: [],
      pact_edited_request_issue_ids: [],
      corrected_request_issue_ids: []
    )

    process_job
    true
  end
  # rubocop:enable Metrics/MethodLength

  # Override the base class's process_job method to set the status to attempted and processed
  def process_job
    update!(last_submitted_at: @parser.end_product_establishment_last_synced_at)
    update!(submitted_at: @parser.end_product_establishment_last_synced_at)
    update!(attempted_at: @parser.end_product_establishment_last_synced_at)
    update!(processed_at: @parser.end_product_establishment_last_synced_at)
  end

  # Process aditional updates for all data that was passed to base class but not processed by it
  # This impliments additional logic for event updates that was not added for intakes
  def process_updated_issues!
    newly_updated_issues = []

    @parser.updated_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      before_data = request_issue.attributes
      update_request_issue!(request_issue, parser_issue)
      add_event_record(request_issue, "U", before_data)
      newly_updated_issues << request_issue
    end

    newly_updated_issues
  end

  def process_withdrawn_issues!
    newly_withdrawn_issues = []
    @parser.withdrawn_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      before_data = request_issue.attributes
      update_request_issue!(request_issue, parser_issue)
      request_issue.withdraw!(parser_issue.ri_closed_at)
      add_event_record(request_issue, "W", before_data)
      newly_withdrawn_issues << request_issue
    end

    newly_withdrawn_issues
  end

  def update_request_issue!(request_issue, parser_issue)
    request_issue.update(mapped_attributes(parser_issue))
  end

  # Set the closed_at date and closed_status for removed issues based on the event data
  def update_removed_issues!
    newly_removed_issues = []

    @parser.removed_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      before_data = request_issue.attributes
      request_issue.remove!
      update_request_issue!(request_issue, parser_issue)
      request_issue.update(
        contention_removed_at: @parser.end_product_establishment_last_synced_at
      )
      add_event_record(request_issue, "R", before_data)
      newly_removed_issues << request_issue
    end

    newly_removed_issues
  end

  def process_eligible_to_ineligible_issues!
    return if @parser.eligible_to_ineligible_issues.empty?

    @parser.eligible_to_ineligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      before_data = request_issue.attributes
      request_issue.remove!
      update_request_issue!(request_issue, parser_issue)
      request_issue.update(
        contention_removed_at: @parser.end_product_establishment_last_synced_at
      )

      add_event_record(request_issue, "E2I", before_data)
    end
  end

  def process_ineligible_to_eligible_issues!
    return if @parser.ineligible_to_eligible_issues.empty?

    @parser.ineligible_to_eligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      before_data = request_issue.attributes
      update_request_issue!(request_issue, parser_issue)
      request_issue.update(
        contention_removed_at: nil
      )

      # LegacyIssue
      process_legacy_issues_for_ineligible_to_eligible!(request_issue, parser_issue)
      add_event_record(request_issue, "I2E", before_data)
    end
  end

  def process_legacy_issues_for_ineligible_to_eligible!(request_issue, parser_issue)
    if vacols_ids_exist?(request_issue)
      legacy_issue = LegacyIssue.find_by(
        request_issue_id: request_issue.id,
        vacols_id: parser_issue.ri_vacols_id,
        vacols_sequence_id: parser_issue.ri_vacols_sequence_id
      )
      reset_or_create_legacy_issue!(legacy_issue, request_issue)
    end
  end

  def reset_or_create_legacy_issue!(legacy_issue, request_issue)
    if legacy_issue && optin? && request_issue.ineligible_reason.blank?
      legacy_issue.legacy_issue_optin.update!(
        optin_processed_at: nil,
        rollback_processed_at: nil,
        rollback_created_at: nil
      )
    else
      legacy_issue = create_legacy_issue_backfill(request_issue)

      # LegacyIssueOptin
      if optin? && request_issue.ineligible_reason.blank?
        create_legacy_optin_backfill(request_issue, legacy_issue)
      end
    end
  end

  def process_ineligible_to_ineligible_issues!
    return if @parser.ineligible_to_ineligible_issues.empty?

    @parser.ineligible_to_ineligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      before_data = request_issue.attributes
      update_request_issue!(request_issue, parser_issue)
      add_event_record(request_issue, "I2I", before_data)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def find_request_issue(parser_issue)
    request_issue = find_by_reference_id(parser_issue) ||
                    find_and_update_original_issue(parser_issue) ||
                    find_and_update_contention_issue(parser_issue)

    if request_issue.nil?
      fail(
        Caseflow::Error::DecisionReviewUpdateMissingIssueError,
        "Reference ID: #{parser_issue.ri_reference_id}, " \
        "Original Reference ID: #{parser_issue.ri_original_caseflow_request_issue_id}"
      )
    end

    request_issue
  end
  # rubocop:enable Metrics/MethodLength

  def add_event_record(request_issue, update_type, before_data)
    EventRecord.create!(
      event: @event,
      evented_record: request_issue,
      info: {
        update_type: update_type,
        record_data: request_issue,
        before_data: before_data
      }
    )
  end

  # iterate through the array of issues and create backfill object from each one
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create_request_issue_backfill
    request_issues = @parser.added_issues
    newly_created_issues = []

    request_issues&.each do |issue|
      # create backfill RI object using extracted values
      parser_issues = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)

      if parser_issues.ri_reference_id.nil?
        fail Caseflow::Error::DecisionReviewCreatedRequestIssuesError, "reference_id cannot be null"
      end

      ri = RequestIssueBuilder.new(parser_issues, @epe.id, @review).build
      add_event_record(ri, "A", nil)
      newly_created_issues.push(ri)

      # LegacyIssue
      if vacols_ids_exist?(ri)
        legacy_issue = create_legacy_issue_backfill(ri)

        # LegacyIssueOptin
        if optin? && ri.ineligible_reason.blank?
          create_legacy_optin_backfill(ri, legacy_issue)
        end
      end
    end
    newly_created_issues
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def find_by_reference_id(parser_issue)
    RequestIssue.find_by(reference_id: parser_issue.ri_reference_id)
  end

  def find_and_update_original_issue(parser_issue)
    original_issue = RequestIssue.find_by(id: parser_issue.ri_original_caseflow_request_issue_id)
    original_issue&.update!(reference_id: parser_issue.ri_reference_id)
    original_issue
  end

  def find_and_update_contention_issue(parser_issue)
    contention_issue = RequestIssue.find_by(contention_reference_id: parser_issue.ri_contention_reference_id)
    contention_issue&.update!(reference_id: parser_issue.ri_reference_id)
    contention_issue
  end

  # Legacy issue checks
  def vacols_ids_exist?(request_issue)
    request_issue.vacols_id.present? && request_issue.vacols_sequence_id.present?
  end

  def optin?
    ActiveModel::Type::Boolean.new.cast(@parser.claim_review_legacy_opt_in_approved)
  end

  def create_legacy_issue_backfill(request_issue)
    legacy_issue = LegacyIssueBuilder.new(request_issue).create_legacy_issue
    add_event_record(li, "A", nil)
    legacy_issue
  end

  def create_legacy_optin_backfill(request_issue, legacy_issue)
    vacols_issue = vacols_issue(request_issue.vacols_id, request_issue.vacols_sequence_id)
    optin = LegacyIssueOptinCreator.create_optin(
      request_issue: request_issue,
      vacols_issue: vacols_issue,
      legacy_issue: legacy_issue
    )
    add_event_record(optin, "A", nil)
    optin
  end

  def vacols_issue(vacols_id, vacols_sequence_id)
    AppealRepository.issues(vacols_id).find do |issue|
      issue.vacols_sequence_id == vacols_sequence_id
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def mapped_attributes(parser_issue)
    {
      ineligible_reason: parser_issue.ri_ineligible_reason,
      closed_at: parser_issue.ri_closed_at,
      closed_status: parser_issue.ri_closed_status,
      contested_issue_description: parser_issue.ri_contested_issue_description,
      nonrating_issue_category: parser_issue.ri_nonrating_issue_category,
      nonrating_issue_description: parser_issue.ri_nonrating_issue_description,
      contention_updated_at: @parser.end_product_establishment_last_synced_at,
      contention_reference_id: parser_issue.ri_contention_reference_id,
      contested_decision_issue_id: parser_issue.ri_contested_decision_issue_id,
      contested_rating_issue_reference_id: parser_issue.ri_contested_rating_issue_reference_id,
      contested_rating_issue_diagnostic_code: parser_issue.ri_contested_rating_issue_diagnostic_code,
      contested_rating_decision_reference_id: parser_issue.ri_contested_rating_decision_reference_id,
      contested_rating_issue_profile_date: parser_issue.ri_contested_rating_issue_profile_date,
      nonrating_issue_bgs_source: parser_issue.ri_nonrating_issue_bgs_source,
      nonrating_issue_bgs_id: parser_issue.ri_nonrating_issue_bgs_id,
      unidentified_issue_text: parser_issue.ri_unidentified_issue_text,
      vacols_sequence_id: parser_issue.ri_vacols_sequence_id,
      ineligible_due_to_id: parser_issue.ri_ineligible_due_to_id,
      reference_id: parser_issue.ri_reference_id,
      rating_issue_associated_at: parser_issue.ri_rating_issue_associated_at,
      edited_description: parser_issue.ri_edited_description,
      ramp_claim_id: parser_issue.ri_ramp_claim_id,
      vacols_id: parser_issue.ri_vacols_id,
      decision_date: parser_issue.ri_decision_date,
      is_unidentified: parser_issue.ri_is_unidentified,
      untimely_exemption: parser_issue.ri_untimely_exemption,
      untimely_exemption_notes: parser_issue.ri_untimely_exemption_notes,
      benefit_type: parser_issue.ri_benefit_type,
      veteran_participant_id: parser_issue.ri_veteran_participant_id
    }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
