# frozen_string_literal: true

class RequestIssuesUpdateEvent < RequestIssuesUpdate
  # example of calling RequestIssuesUpdateEvent
  # RequestIssuesUpdateEvent.new(
  #   user: user,
  #   review: review,
  #   parser: parser
  # )

  def initialize(user:, review:, parser:)
    @parser = parser
    super(user: user, review: review)

    @eligible_to_ineligible_issue_data = parser.eligible_to_ineligible_issues
    @ineligible_to_ineligible_issue_data = parser.ineligible_to_ineligible_issues
    @ineligible_to_eligible_issue_data = parser.ineligible_to_eligible_issues
    @withdrawn_issue_data = parser.withdrawn_issues
    @edited_issue_data = parser.updated_issues
    @removed_issue_data = parser.removed_issues
    @added_issue_data = parser.added_issues
  end

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      process_issues!
      # updates rating_issue_associated_at of review's issues to nil
      review.mark_rating_request_issues_to_reassociate!
      update!(
        before_request_issue_ids: before_issues.map(&:reference_id),
        after_request_issue_ids: after_issues.map(&:reference_id),
        withdrawn_request_issue_ids: withdrawn_issues.map(&:reference_id),
        edited_request_issue_ids: edited_issues.map(&:reference_id)
      )
    end

    process_job

    true
  end

  def process_issues!
    process_added_issues!
    process_removed_issues!
    process_legacy_issues!
    process_withdrawn_issues!
    process_edited_issues!
    process_eligible_to_ineligible_issues!
    process_ineligible_to_eligible_issues!
    process_ineligible_to_ineligible_issues!
  end

  def process_added_issues!
    review.create_issues!(added_issues, self)
  end

  def process_removed_issues!
    return if removed_issues.nil?

    removed_issues.each(&:remove!)
  end

  def added_issues
    calculate_added_issues
  end

  def removed_issues
    return if @removed_issue_data.empty?

    @removed_issue_data.map do |issue_data|
      issue = review.request_issues.find_by(reference_id: issue_data[:reference_id])
      unless issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, issue_data[:reference_id]
      end

      issue
    end
  end

  def withdrawn_issues
    @withdrawn_issues ||= withdrawn_request_issue_ids ? fetch_withdrawn_issues : calculate_withdrawn_issues
  end

  def all_updated_issues
    (added_issues || []) + (removed_issues || []) + (withdrawn_issues || []) + (edited_issues || [])
  end

  private

  def process_edited_issues!
    return if @edited_issue_data.empty?

    @edited_issue_data.each do |issue_data|
      request_issue = review.request_issues.find_by(reference_id: issue_data[:reference_id])
      unless request_issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, issue_data[:reference_id]
      end

      request_issue.save_edited_contention_text!(issue_data[:edited_description])
      request_issue.save_decision_date!(issue_data[:decision_date]) if issue_data[:decision_date]
    end
  end

  def changes?
    all_updated_issues.any?
  end

  def calculate_after_issues
    (before_issues || []) + (added_issues || []) - (removed_issues || [])
  end

  def calculate_edited_issues
    calculate_issues(@edited_issue_data)
  end

  def calculate_added_issues
    calculate_issues(@added_issue_data)
  end

  def calculate_withdrawn_issues
    calculate_issues(@withdrawn_issue_data)
  end

  def calculate_issues(issues_data)
    issues_data.map do |issue_data|
      find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def find_or_build_request_issue_from_intake_data(issue_data)
    # find exising issue or build a new one
    # this method is based on the find_or_build_request_issue_from_intake_data
    # method in the DecisionReview model which uses :requested_issue_id key
    # when in our case parser returns issue_data with :reference_id key
    begin
      return review.request_issues.find_by(reference_id: issue_data[:reference_id]) if issue_data[:reference_id]
    rescue ActiveRecord::RecordNotFound
      raise Caseflow::Error::DecisionReviewUpdateMissingIssueError, issue_data[:reference_id]
    end
    from_intake_data(issue_data, decision_review: review)
  end

  def from_intake_data(data, decision_review: nil)
    attrs = attributes_from_intake_data(data)
    attrs = attrs.merge(decision_review: decision_review) if decision_review

    RequestIssue.new(attrs).tap(&:validate_eligibility!)
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Layout/LineLength
  def attributes_from_intake_data(data)
    parser_issue = Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser.new(data)
    contested_issue_present = attributes_look_like_contested_issue?(data)
    issue_text = data[parser_issue.ri_is_unidentified] ? data[parser_issue.ri_contested_issue_description] : nil

    {
      benefit_type: data[parser_issue.ri_benefit_type],
      closed_at: data[parser_issue.ri_closed_at],
      closed_status: data[parser_issue.ri_closed_status],
      contention_reference_id: data[parser_issue.ri_contention_reference_id],
      contested_decision_issue_id: data[parser_issue.ri_contested_decision_issue_id],
      contested_rating_issue_reference_id: data[parser_issue.ri_contested_rating_issue_reference_id],
      contested_rating_issue_diagnostic_code: data[parser_issue.ri_contested_rating_issue_diagnostic_code],
      contested_rating_decision_reference_id: data[parser_issue.ri_contested_rating_decision_reference_id],
      contested_issue_description: contested_issue_present ? data[parser_issue.ri_contested_issue_description] : nil,
      contested_rating_issue_profile_date: data[parser_issue.ri_contested_rating_issue_profile_date],
      nonrating_issue_description: data[parser_issue.ri_nonrating_issue_category] ? data[parser_issue.ri_contested_issue_description] : nil,
      unidentified_issue_text: issue_text,
      decision_date: data[parser_issue.ri_decision_date],
      nonrating_issue_category: data[parser_issue.ri_nonrating_issue_category],
      is_unidentified: data[parser_issue.ri_is_unidentified],
      untimely_exemption: data[parser_issue.ri_untimely_exemption],
      untimely_exemption_notes: data[parser_issue.ri_untimely_exemption_notes],
      ramp_claim_id: data[parser_issue.ri_ramp_claim_id],
      vacols_id: data[parser_issue.ri_vacols_id],
      vacols_sequence_id: data[parser_issue.ri_vacols_sequence_id],
      ineligible_reason: data[parser_issue.ri_ineligible_reason],
      ineligible_due_to_id: data[parser_issue.ri_ineligible_due_to_id],
      reference_id: data[parser_issue.ri_reference_id],
      type: data[parser_issue.ri_type],
      veteran_participant_id: data[parser_issue.ri_veteran_participant_id],
      rating_issue_associated_at: data[parser_issue.ri_rating_issue_associated_at],
      nonrating_issue_bgs_source: data[parser_issue.ri_nonrating_issue_bgs_source],
      nonrating_issue_bgs_id: data[parser_issue.ri_nonrating_issue_bgs_id]
    }
  end

  def attributes_look_like_contested_issue?(data)
    data[:ri_contested_rating_issue_reference_id] ||
      data[:ri_contested_decision_issue_id] ||
      data[:ri_contested_rating_decision_reference_id] ||
      data[:ri_contested_rating_issue_diagnostic_code]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Layout/LineLength

  def fetch_withdrawn_issues
    RequestIssue.where(reference_id: withdrawn_request_issue_ids)
  end

  def process_withdrawn_issues!
    return if @withdrawn_issue_data.empty?

    @withdrawn_issue_data.each do |withdrawn_issue|
      issue = request_issue = RequestIssue.find_by(reference_id: withdrawn_issue[:reference_id].to_s)
      unless issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, withdrawn_issue[:reference_id]
      end

      request_issue.withdraw!(withdrawn_issue[:closed_at])
    end
  end

  def process_eligible_to_ineligible_issues!
    return if @eligible_to_ineligible_issue_data.empty?

    @eligible_to_ineligible_issue_data.each do |issue_data|
      request_issue = review.request_issues.find_by(reference_id: issue_data[:reference_id])
      unless request_issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, issue_data[:reference_id]
      end

      request_issue.update(
        ineligible_reason: issue_data[:ineligible_reason],
        closed_at: issue_data[:closed_at],
        contention_reference_id: nil
      )
    end
  end

  def process_ineligible_to_eligible_issues!
    return if @ineligible_to_eligible_issue_data.empty?

    @ineligible_to_eligible_issue_data.each do |issue_data|
      issue = review.request_issues.find_by(reference_id: issue_data[:reference_id])
      unless issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, issue_data[:reference_id]
      end

      issue.update(ineligible_reason: nil, closed_status: nil, closed_at: nil)
    end
  end

  def process_ineligible_to_ineligible_issues!
    return if @ineligible_to_ineligible_issue_data.empty?

    @ineligible_to_ineligible_issue_data.each do |issue_data|
      issue = review.request_issues.find_by(reference_id: issue_data[:reference_id])
      unless issue
        fail Caseflow::Error::DecisionReviewUpdateMissingIssueError, issue_data[:reference_id]
      end

      issue.update(
        ineligible_reason: issue_data[:ineligible_reason],
        closed_at: issue_data[:closed_at],
        contention_reference_id: nil
      )
    end
  end
end
