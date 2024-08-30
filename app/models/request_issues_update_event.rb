# frozen_string_literal: true

class RequestIssuesUpdateEvent < RequestIssuesUpdate
  # example of calling RequestIssuesUpdateEvent
  # RequestIssuesUpdateEvent.new(
  #   user: user,
  #   review: review,
  #   added_issues_data: parser.added_issues,
  #   removed_issues_data: parser.removed_issues,
  #   edited_issues_data: parser.updated_issues,
  #   withdrawn_issues_data: parser.withdrawn_issues
  #   eligible_to_ineligible_issues_data: parser.eligible_to_ineligible_issues
  #   ineligible_to_eligible_issues_data: parser.ineligible_to_eligible_issues
  #   ineligible_to_ineligible_issues_data: parser.ineligible_to_ineligible_issues
  # )

  attr_writer :added_issues_data
  attr_writer :removed_issues_data
  attr_writer :edited_issues_data
  attr_writer :withdrawn_issues_data
  attr_writer :eligible_to_ineligible_issues_data
  attr_writer :ineligible_to_eligible_issues_data
  attr_writer :ineligible_to_ineligible_issues_data

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      process_issues!
      # updates rating_issue_associated_at of review's issues to nil
      review.mark_rating_request_issues_to_reassociate!
      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id),
        withdrawn_request_issue_ids: withdrawn_issues.map(&:id),
        edited_request_issue_ids: edited_issues.map(&:id)
      )
    end

    process_job

    true
  end

  def added_issues
    calculate_added_issues
  end

  def removed_issues
    calculate_removed_issues
  end

  def withdrawn_issues
    @withdrawn_issues ||= withdrawn_request_issue_ids ? fetch_withdrawn_issues : calculate_withdrawn_issues
  end

  def all_updated_issues
    added_issues + removed_issues + withdrawn_issues + edited_issues
  end

  def eligible_to_ineligible; end

  def ineligible_to_eligible; end

  def ineligible_to_ineligible; end

  private

  def changes?
    all_updated_issues.any?
  end

  def calculate_after_issues
    before_issues + added_issues - removed_issues
  end

  def calculate_edited_issues
    calculate_issues(@edited_issues_data)
  end

  def calculate_added_issues
    calculate_issues(@added_issues_data)
  end

  def calculate_withdrawn_issues
    calculate_issues(@withdrawn_issues_data)
  end

  def calculate_removed_issues
    @removed_issues_data.map do |issue_data|
      review.request_issues.find(issue_data[:id])
    end
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
    # when in our case parser returns issue_data with :id key
    return review.request_issues.find(issue_data[:id]) if issue_data[:id]

    # probably we will use our own method for that operation insted of "from_intake_data"
    # that will be called from future UpdateRequestIssues service class
    # if not we HAVE TO update or override from_intake_data for new
    # attribute vbms_id
    RequestIssue.from_intake_data(issue_data, decision_review: review)
  end

  def fetch_withdrawn_issues
    RequestIssue.where(id: withdrawn_request_issue_ids)
  end

  def process_withdrawn_issues!
    return if withdrawn_issues.empty?

    @withdrawn_issues_data.each do |withdrawn_issue|
      request_issue = RequestIssue.find(withdrawn_issue[:id].to_s)
      request_issue.withdraw!(withdrawn_issue[:closed_at])
    end
  end

  def process_edited_issues!
    # method is updated since parser returns issue_data with :id key instead :request_issue_id
    return if edited_issues.empty?

    edited_issue_data.each do |edited_issue|
      request_issue = RequestIssue.find(edited_issue[:id].to_s)
      edit_contention_text(edited_issue, request_issue)
      edit_decision_date(edited_issue, request_issue)
    end
  end

  def process_eligible_to_ineligible_issues!
    return if eligible_to_ineligible_issues.empty?

    eligible_to_ineligible_issues_data.each do |eligible_to_ineligible_issue|
      request_issue = RequestIssue.find(eligible_to_ineligible_issue[:id].to_s)
      next if !request_issue.ineligible_reason.nil?

      request_issue.update(ineligible_reason: eligible_to_ineligible_issue.ineligible_reason,
                           closed_at: ineligible_to_ineligible_issue.closed_at)
    end
  end

  def process_ineligible_to_eligible_issues!
    return if ineligible_to_eligible_issues.empty?

    ineligible_to_eligible_issues_data.each do |ineligible_to_eligible_issue|
      request_issue = RequestIssue.find(ineligible_to_eligible_issue[:id].to_s)
      next if request_issue.ineligible_reason.nil?

      request_issue.update(ineligible_reason: nil, closed_status: nil, closed_at: nil)
    end
  end

  def process_ineligible_to_ineligible_issues!
    return if ineligible_to_ineligible_issues.empty?

    ineligible_to_ineligible_issues_data.each do |ineligible_to_ineligible_issue|
      request_issue = RequestIssue.find(ineligible_to_ineligible_issue[:id].to_s)
      next if request_issue.ineligible_reason.nil?

      request_issue.update(ineligible_reason: ineligible_to_ineligible_issue.ineligible_reason,
                           closed_at: ineligible_to_ineligible_issue.closed_at)
      # closed_at from parser has milliseconds format.
    end
  end

  def edit_contention_text(edited_issue_params, request_issue)
    # method is updated since parser returns issue_data with :edited_description key instead :edited_description
    if edited_issue_params[:edited_description]
      request_issue.save_edited_contention_text!(edited_issue_params[:edited_description])
    end
  end

  def edit_decision_date(edited_issue_params, request_issue)
    # method is updated since parser returns issue_data with :decision_date key instead :edited_decision_date
    if edited_issue_params[:decision_date]
      request_issue.save_decision_date!(edited_issue_params[:decision_date])
    end
  end
end
