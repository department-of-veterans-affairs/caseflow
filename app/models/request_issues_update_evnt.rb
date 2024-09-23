# frozen_string_literal: true

class RequestIssuesUpdateEvnt < RequestIssuesUpdate
  def initialize(review:, user:, parser:)
    @parser = parser
    @request_issues_data = build_request_issues_data
    super(
      user: user,
      review: review,
      request_issues_data: @request_issues_data
    )
  end

  # closures havppen by calling liunes similar to that in EP establishment line 460
  # should not add closure issues becused the base class calcuates the delta from before and after
  # Question: should there be handling for corrected issues?
  # Contentions are never removed, contention_removed_date is set instead
  # do we need to update attributes for eligibility change issues or just status?

  def perform!
    # Call the base class's perform! method
    result = super
    if result
      remove_request_issues_with_no_decision!
      process_eligible_to_ineligible_issues!
      process_ineligible_to_eligible_issues!
      process_ineligible_to_ineligible_issues!
      true
    else
      false
    end
  end

  def process_eligible_to_ineligible_issues!
    return if @parser.eligible_to_ineligible_issues.empty?

    @parser.eligible_to_ineligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = review.request_issues.find_by(reference_id: parser_issue.ri_reference_id)
      unless request_issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, parser_issue.ri_reference_id
      end

      request_issue.update(
        ineligible_reason: parser_issue.ri_ineligible_reason,
        closed_at: parser_issue.ri_closed_at,
      )
      RequestIssueContention.new(request_issue).remove!
    end
  end

  def process_ineligible_to_eligible_issues!
    return if @parser.ineligible_to_eligible_issues.empty?

    @parser.ineligible_to_eligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = review.request_issues.find_by(reference_id: parser_issue.ri_reference_id)
      unless request_issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, parser_issue.ri_reference_id
      end
      request_issue.update(
        ineligible_reason: nil,
        closed_status: nil,
        closed_at: nil
      )
    end
  end

  def process_ineligible_to_ineligible_issues!
    return if @parser.ineligible_to_ineligible_issues.empty?

    @parser.ineligible_to_ineligible_issues.each do |issue_data|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue_data)
      request_issue = review.request_issues.find_by(reference_id: parser_issue.ri_reference_id)
      unless request_issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, parser_issue.ri_reference_id
      end

      request_issue.update(
        ineligible_reason: parser_issue.ri_ineligible_reason,
        closed_at: parser_issue.ri_closed_at,
      )
    end
  end

  # check to see if the there are closed issues that are deferent from before - after
  # if so, then raise an error

  def remove_request_issues_with_no_decision!
    return if @parser.removed_issues.empty?

    check_for_mismatched_closed_issues!
    @parser.removed_issues.each do |issue|
      RequestIssueClosure.new(issue).with_no_decision!
    end
  end

  def check_for_mismatched_closed_issues!
    parser_removed_issues = @parser.removed_issues.map do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      parser_issue.ri_reference_id
    end
    base_removed_issues = removed_issues.map(&:reference_id)

    # Check for issues in parser.removed_issues but not in base removed_issues
    parser_only = parser_removed_issues - base_removed_issues
    # Check for issues in base removed_issues but not in parser.removed_issues
    base_only = base_removed_issues - parser_removed_issues

    if parser_only.any? || base_only.any?
      raise Caseflow::Error::DecisionReviewUpdateMismatchedRemovedIssuesError,
            "Mismatched removed issues: CaseFlow only = #{base_only.join(', ')} - Event only = #{parser_only.join(', ')}"
    end
    true
  end

  # Add any other methods you need
  def build_request_issues_data
    @request_issues_data = []

    # Handle updated issues
    @parser.updated_issues.each do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      @request_issues_data << build_issue_data(parser_issue: parser_issue)
    end

    # Handle withdrawn issues
    @parser.withdrawn_issues.each do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      @request_issues_data << build_issue_data(parser_issue: parser_issue, is_withdrawn: true)
    end

    # Handle added issues
    @parser.added_issues.each do |issue|
      parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(issue)
      @request_issues_data << build_issue_data(parser_issue: parser_issue, is_new: true)
    end

    @request_issues_data
  end

  def build_issue_data(parser_issue:, is_withdrawn: false, is_new: false)
    return {} if parser_issue.nil?

    {
      request_issue_id: is_new ? nil : find_request_issue_id(parser_issue),
      benefit_type: parser_issue.ri_benefit_type,
      closed_date: parser_issue.ri_closed_at,
      withdrawal_date: is_withdrawn ? parser_issue.ri_closed_at : nil,
      closed_status: parser_issue.ri_closed_status,
      contention_reference_id: parser_issue.ri_contention_reference_id,
      contested_decision_issue_id: parser_issue.ri_contested_decision_issue_id,
      contested_rating_issue_reference_id: parser_issue.ri_contested_rating_issue_reference_id,
      contested_rating_issue_diagnostic_code: parser_issue.ri_contested_rating_issue_diagnostic_code,
      contested_rating_decision_reference_id: parser_issue.ri_contested_rating_decision_reference_id,
      contested_issue_description: parser_issue.ri_contested_issue_description,
      contested_rating_issue_profile_date: parser_issue.ri_contested_rating_issue_profile_date,
      nonrating_issue_description: parser_issue.ri_nonrating_issue_category ? parser_issue.ri_contested_issue_description : nil,
      unidentified_issue_text: parser_issue.ri_unidentified_issue_text,
      decision_date: parser_issue.ri_decision_date,
      nonrating_issue_category: parser_issue.ri_nonrating_issue_category,
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
      veteran_participant_id: parser_issue.ri_veteran_participant_id,
      rating_issue_associated_at: parser_issue.ri_rating_issue_associated_at,
      nonrating_issue_bgs_source: parser_issue.ri_nonrating_issue_bgs_source,
      nonrating_issue_bgs_id: parser_issue.ri_nonrating_issue_bgs_id
    }
  end

  def find_request_issue_id(parser_issue)
    request_issue = RequestIssue.find_by(reference_id: parser_issue.ri_reference_id)
    if request_issue
      request_issue.id
    else
      raise(Caseflow::Error::DecisionReviewUpdateMissingIssueError, parser_issue.ri_reference_id)
    end
  end
end
