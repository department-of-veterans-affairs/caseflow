# frozen_string_literal: true

# has issue modification request business login.

class NonAdmin::IssueModificationRequestsUpdater
  def initialize(current_user:, review:, issue_modifications_data:)
    @current_user = current_user
    @review = review
    @issue_modifications_data = issue_modifications_data
  end

  attr_accessor :current_user, :review, :issue_modifications_data, :requestor

  REQUEST_TYPE = {
    addition: "addition",
    removal: "removal",
    modification: "modification",
    withdrawal: "withdrawal"
  }.freeze

  STATUS = {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }.freeze

  NEW_REQUEST_ERROR = "Issue status must be in an assigned".freeze
  MODIFICATION_ERROR = "Must be the same requestor or request must be in assigned state".freeze

  def perform!
    new_modifications_process!(issue_modifications_data[:new])
    edit_modifications_process!(issue_modifications_data[:edited])
    canceled_modifications_process!(issue_modifications_data[:canceled])
  end

  private


  def new_modifications_process!(new_issues)
    new_issues.each do |new_issue|
      validate_new_issues!(status: new_issue[:status])
      IssueModificationRequest.create!(
        decision_review: review,
        request_type: new_issue[:request_type],
        request_reason: new_issue[:request_reason],
        benefit_type: new_issue[:benefit_type],
        decision_date: new_issue[:decision_date],
        decided_decision_text: new_issue[:decision_text],
        nonrating_issue_category: new_issue[:nonrating_issue_category],
        status: new_issue[:status],
        requestor_id: new_issue[:requestor_id]
      )
    end
  end

  def edit_modifications_process!(edited_issues)
    edited_issues.each do |edited_issue|
      validate_issues_request!(
        requestor_id: edited_issue[:requestor_id],
        status: edited_issue[:status]
      )
      find_modification_request(edited_issue[:id]).update!(
        nonrating_issue_category: edited_issue[:nonrating_issue_category],
        decision_date: edited_issue[:decision_date],
        decided_decision_text: edited_issue[:decision_text],
        request_reason: edited_issue[:request_reason]
      )
    end
  end

  def canceled_modifications_process!(canceled_issues)
    canceled_issues.each do |canceled_issue|
      validate_issues_request!(
        requestor_id: canceled_issue[:requestor_id],
        status: canceled_issue[:status])
      find_modification_request(canceled_issue[:id]).destroy!
    end
  end


  private

  def validate_new_issues!(status:)
    fail StandardError, NEW_REQUEST_ERROR if STATUS[:assigned] != status.downcase
  end

  def validate_issues_request!(requestor_id:, status:)
    if current_user != requestor(requestor_id) && STATUS[:assigned] != status.downcase
      fail StandardError, MODIFICATION_ERROR
    end
  end

  def request_issue(id)
    @request_issue = RequestIssue.find(id)
  end

  def find_modification_request(id)
    @issue_modification_request = IssueModificationRequest.find(id)
  end

  def requestor(id)
    @requestor = User.find(id)
  end
end

