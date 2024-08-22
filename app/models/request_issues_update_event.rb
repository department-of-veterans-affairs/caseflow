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
  # )

  attr_writer :added_issues_data
  attr_writer :removed_issues_data
  attr_writer :edited_issues_data
  attr_writer :withdrawn_issues_data

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      process_issues!
      review.mark_rating_request_issues_to_reassociate!
      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id),
        withdrawn_request_issue_ids: withdrawn_issues.map(&:id),
        edited_request_issue_ids: edited_issues.map(&:id)
      )
    end
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

    RequestIssue.from_intake_data(issue_data, decision_review: review)
  end

  def validate_before_perform
    if !changes?
      @error_code = :no_changes
    elsif RequestIssuesUpdate.where(review: review).where.not(id: id).processable.exists?
      @error_code = :previous_update_not_done_processing
    end

    !@error_code
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
