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
  def initialize(review:, user:, parser:, event:)
    @event = event
    @parser = parser
    @review = review
    build_request_issues_data
    super(
      user: user,
      review: review,
      request_issues_data: @request_issues_data
    )
  end

  def perform!
    # Call the base class's perform! method
    result = super
    if result || !changes?
      process_eligible_to_ineligible_issues!
      process_ineligible_to_eligible_issues!
      process_ineligible_to_ineligible_issues!
      process_request_issues_data!
      update_removed_issues!
      process_audit_records!
      true
    else
      false
    end
  end

  # This method may create more than one audit record for a single issue
  # if the issue is updated in multiple ways such as a desctiption change
  # and a withdrawal
  def process_audit_records!
    return true if all_updated_issues.empty?

    edited_issues.each do |request_issue|
      add_event_record(request_issue, "E")
    end

    added_issues.each do |request_issue|
      add_event_record(request_issue, "A")
    end

    removed_issues.each do |request_issue|
      add_event_record(request_issue, "R")
    end

    withdrawn_issues.each do |request_issue|
      add_event_record(request_issue, "W")
    end
  end

  # Override the base class's process_job method to set the status to attempted and processed
  def process_job
    update!(last_submitted_at: @parser.end_product_establishment_last_synced_at)
    update!(submitted_at: @parser.end_product_establishment_last_synced_at)
    update!(attempted_at: @parser.end_product_establishment_last_synced_at)
    update!(processed_at: @parser.end_product_establishment_last_synced_at)
  end

  # Process aditional updates for all data that was passed to base class but not processed by it
  # This impliments additional logic for event updates that was not added for intakes
  def process_request_issues_data!
    return true if after_issues.empty?

    (added_issues + edited_issues).each do |request_issue|
      issue_data =
        @request_issues_data.find { |data| data[:reference_id] == request_issue.reference_id }

      next if issue_data.nil?

      update_data_not_processed_in_base_class!(request_issue, issue_data)
    end
    true
  end

  def update_data_not_processed_in_base_class!(request_issue, issue_data)
    request_issue.update(
      contested_issue_description:
        issue_data[:contested_issue_description] || request_issue.contested_issue_description,
      nonrating_issue_category:
        issue_data[:nonrating_issue_category] || request_issue.nonrating_issue_category,
      nonrating_issue_description:
        issue_data[:nonrating_issue_description] || request_issue.nonrating_issue_description,
      contention_updated_at: issue_data[:edited_description] ? @parser.end_product_establishment_last_synced_at : nil,
      contention_reference_id: issue_data[:contention_reference_id].to_i || request_issue.contention_reference_id,
      ineligible_reason: issue_data[:ineligible_reason],
      closed_at: issue_data[:closed_at],
      closed_status: issue_data[:closed_status],
      nonrating_issue_bgs_id: issue_data[:nonrating_issue_bgs_id],
      unidentified_issue_text: issue_data[:unidentified_issue_text],
      vacols_sequence_id: issue_data[:vacols_sequence_id],
      contested_rating_issue_diagnostic_code: issue_data[:contested_rating_issue_diagnostic_code]
    )
  end

  # Set the closed_at date and closed_status for removed issues based on the event data
  def update_removed_issues!
    removed_issues.each do |request_issue|
      issue_data =
        @parser.removed_issues.find do |data|
          parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(data)
          parser_issue.ri_reference_id == request_issue.reference_id
        end

      next if issue_data.nil?

      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue.update(
        closed_at: parser_issue.ri_closed_at,
        closed_status: parser_issue.ri_closed_status,
        contention_removed_at: @parser.end_product_establishment_last_synced_at,
        contention_updated_at: @parser.end_product_establishment_last_synced_at
      )
    end
    true
  end

  def process_eligible_to_ineligible_issues!
    return if @parser.eligible_to_ineligible_issues.empty?

    @parser.eligible_to_ineligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)

      request_issue.update(
        ineligible_reason: parser_issue.ri_ineligible_reason,
        closed_at: parser_issue.ri_closed_at,
        contested_issue_description: parser_issue.ri_contested_issue_description ||
          request_issue.contested_issue_description,
        nonrating_issue_category: parser_issue.ri_nonrating_issue_category ||
          request_issue.nonrating_issue_category,
        nonrating_issue_description: parser_issue.ri_nonrating_issue_description ||
          request_issue.nonrating_issue_description,
        contention_removed_at: @parser.end_product_establishment_last_synced_at,
        contention_updated_at: @parser.end_product_establishment_last_synced_at,
        contention_reference_id: parser_issue.ri_contention_reference_id
      )
      add_event_record(request_issue, "E2I")
    end
  end

  def process_ineligible_to_eligible_issues!
    return if @parser.ineligible_to_eligible_issues.empty?

    @parser.ineligible_to_eligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)
      request_issue.update(
        ineligible_reason: nil,
        closed_status: nil,
        closed_at: nil,
        contention_reference_id: parser_issue.ri_contention_reference_id,
        contention_removed_at: nil,
        contested_issue_description: parser_issue.ri_contested_issue_description ||
          request_issue.contested_issue_description,
        nonrating_issue_category: parser_issue.ri_nonrating_issue_category ||
          request_issue.nonrating_issue_category,
        nonrating_issue_description: parser_issue.ri_nonrating_issue_description ||
          request_issue.nonrating_issue_description,
        contention_updated_at: @parser.end_product_establishment_last_synced_at
      )
      add_event_record(request_issue, "I2E")
    end
  end

  def process_ineligible_to_ineligible_issues!
    return if @parser.ineligible_to_ineligible_issues.empty?

    @parser.ineligible_to_ineligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = find_request_issue(parser_issue)

      request_issue.update(
        ineligible_reason: parser_issue.ri_ineligible_reason,
        closed_at: parser_issue.ri_closed_at,
        contested_issue_description: parser_issue.ri_contested_issue_description ||
          request_issue.contested_issue_description,
        nonrating_issue_category: parser_issue.ri_nonrating_issue_category ||
          request_issue.nonrating_issue_category,
        nonrating_issue_description: parser_issue.ri_nonrating_issue_description ||
          request_issue.nonrating_issue_description,
        contention_removed_at: @parser.end_product_establishment_last_synced_at,
        contention_updated_at: @parser.end_product_establishment_last_synced_at,
        contention_reference_id: parser_issue.ri_contention_reference_id
      )
      add_event_record(request_issue, "I2I")
    end
  end

  # Assymble the request issues data in the format expected by the base class
  def build_request_issues_data
    @request_issues_data = []

    # Add updated issues
    @parser.updated_issues.each do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      @request_issues_data << build_issue_data(parser_issue: parser_issue)
    end

    # Add withdrawn issues
    @parser.withdrawn_issues.each do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      @request_issues_data << build_issue_data(parser_issue: parser_issue, is_withdrawn: true)
    end

    # Add added issues
    @parser.added_issues.each do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      @request_issues_data << build_issue_data(parser_issue: parser_issue, is_new: true)
    end

    # This is to ensure all request issues associated with the review are included in the after_issues
    add_existing_review_issues

    @request_issues_data
  end

  # Add all review issue ids and reference ids not included in the request_issues_data
  # but not included in the removed_issues
  # Note that removed issues are not included in the request_issues_data
  # This is to ensure all removed issues are derived from the (before - after) comparison in base class
  def add_existing_review_issues
    @review.request_issues.each do |request_issue|
      # Skip if the request issue is already in the request_issues_data
      next if @request_issues_data.find do |data|
        data[:reference_id] == request_issue.reference_id ||
        data[:original_caseflow_request_issue_id] == request_issue.id
      end

      # Skip if the request issue is in the removed_issues
      next if @parser.removed_issues.find do |data|
        parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(data)
        parser_issue.ri_reference_id == request_issue.reference_id ||
        parser_issue.ri_original_caseflow_request_issue_id == request_issue.id
      end

      # Only add the reference_id and request_issue_id to the request_issues_data
      # The base class does not need to update existing issues not included in event data
      @request_issues_data << {
        request_issue_id: request_issue.id,
        reference_id: request_issue.reference_id
      }
    end
    @request_issues_data
  end

  # Orveride removed_issues to explicity set the removed issues received from the event
  # Thechnically these issues are calculated by the base class, but this is more direct
  def removed_issues
    @parser.removed_issues.map do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      find_request_issue(parser_issue)
    end
  end

  # Build the request issue data in the format expected by the base class
  # This is for event updates to follow the same logic as an intake that created from the UI
  def build_issue_data(parser_issue:, is_withdrawn: false, is_new: false)
    return {} if parser_issue.nil?

    issue_data = base_issue_data(parser_issue)
    issue_data.merge!(contested_issue_data(parser_issue))
    issue_data.merge!(nonrating_issue_data(parser_issue))
    issue_data.merge!(conditional_issue_data(parser_issue, is_withdrawn, is_new))
    issue_data
  end

  # Add base issue data to the issue data
  def base_issue_data(parser_issue)
    {
      benefit_type: parser_issue.ri_benefit_type,
      closed_date: parser_issue.ri_closed_at,
      closed_status: parser_issue.ri_closed_status,
      unidentified_issue_text: parser_issue.ri_unidentified_issue_text,
      issue_text: parser_issue.ri_unidentified_issue_text,
      decision_date: parser_issue.ri_decision_date,
      is_unidentified: parser_issue.ri_is_unidentified,
      untimely_exemption: parser_issue.ri_untimely_exemption,
      untimely_exemption_notes: parser_issue.ri_untimely_exemption_notes,
      ramp_claim_id: parser_issue.ri_ramp_claim_id,
      vacols_id: parser_issue.ri_vacols_id,
      vacols_sequence_id: parser_issue.ri_vacols_sequence_id,
      ineligible_reason: parser_issue.ri_ineligible_reason,
      ineligible_due_to_id: parser_issue.ri_ineligible_due_to_id,
      reference_id: parser_issue.ri_reference_id,
      type: parser_issue.ri_type,
      rating_issue_associated_at: parser_issue.ri_rating_issue_associated_at,
      edited_description: parser_issue.ri_edited_description
    }
  end

  # Add the request issue id to the issue data if it is a new issue
  # Add addtional fields that are userd buy the base class to identify the type of update
  def conditional_issue_data(parser_issue, is_withdrawn, is_new)
    {
      request_issue_id: is_new ? nil : find_request_issue(parser_issue).id,
      withdrawal_date: is_withdrawn ? parser_issue.ri_closed_at : nil,
      decision_text: parser_issue.ri_nonrating_issue_description,
      end_product_code: @parser.end_product_establishment_code
    }
  end

  # Add nonrating issue data to the issue data
  def nonrating_issue_data(parser_issue)
    {
      nonrating_issue_category: parser_issue.ri_nonrating_issue_category,
      nonrating_issue_description: parser_issue.ri_nonrating_issue_description,
      nonrating_issue_bgs_source: parser_issue.ri_nonrating_issue_bgs_source,
      nonrating_issue_bgs_id: parser_issue.ri_nonrating_issue_bgs_id
    }
  end

  # Add contested issue data to the issue data
  def contested_issue_data(parser_issue)
    {
      contention_reference_id: parser_issue.ri_contention_reference_id,
      contested_decision_issue_id: parser_issue.ri_contested_decision_issue_id,
      contested_rating_issue_reference_id: parser_issue.ri_contested_rating_issue_reference_id,
      contested_rating_issue_diagnostic_code: parser_issue.ri_contested_rating_issue_diagnostic_code,
      contested_rating_decision_reference_id: parser_issue.ri_contested_rating_decision_reference_id,
      contested_issue_description: parser_issue.ri_contested_issue_description,
      contested_rating_issue_profile_date: parser_issue.ri_contested_rating_issue_profile_date
    }
  end

  def find_request_issue(parser_issue)
    request_issue = RequestIssue.find_by(reference_id: parser_issue.ri_reference_id)

    if request_issue.nil?
      original_request_issue = RequestIssue.find_by(id: parser_issue.ri_original_caseflow_request_issue_id)

      if original_request_issue
        original_request_issue.update!(reference_id: parser_issue.ri_reference_id)
        request_issue = original_request_issue
      end
    end

    if request_issue.nil?
      fail(
        Caseflow::Error::DecisionReviewUpdateMissingIssueError,
        "Reference ID: #{parser_issue.ri_reference_id}, " \
        "Original Reference ID: #{parser_issue.ri_original_caseflow_request_issue_id}"
      )
    end

    request_issue
  end

  def add_event_record(request_issue, update_type)
    EventRecord.create!(
      event: @event,
      evented_record: request_issue,
      info: { update_type: update_type, record_data: request_issue }
    )
  end
end
