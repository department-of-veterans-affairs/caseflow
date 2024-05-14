# frozen_string_literal: true

# has issue modification request business login.

class NonAdmin::IssueModificationRequestsUpdater
  def initialize(current_user:, review:, issue_modifications_data:)
    @current_user = current_user
    @review = review
    @issue_modifications_data = issue_modifications_data
  end

  attr_accessor :current_user, :review, :issue_modifications_data, :requestor, :error_code

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

  def process!
    new_modifications_process!(issue_modifications_data[:new]) if issue_modifications_data[:new].any?
    edit_modifications_process!(issue_modifications_data[:edited]) if issue_modifications_data[:edited].any?
    canceled_modifications_process!(issue_modifications_data[:canceled]) if issue_modifications_data[:canceled].any?
  end

  def success?
    error_code.nil?
  end

  private

  def new_modifications_process!(new_issues)
    new_issues.each do |new_issue|
      unless validate_new_issues?(status: new_issue[:status])
        @error_code = NEW_REQUEST_ERROR
        return false
      end
      IssueModificationRequest.create!(
        decision_review: review,
        request_type: new_issue[:request_type],
        request_reason: new_issue[:request_reason],
        benefit_type: new_issue[:benefit_type],
        decision_date: new_issue[:decision_date],
        decider_note: new_issue[:decider_note],
        nonrating_issue_category: new_issue[:nonrating_issue_category],
        nonrating_issue_description: new_issue[:nonrating_issue_description],
        status: new_issue[:status],
        requestor_id: new_issue[:requestor_id]
      )
    end

    true
  end

  def edit_modifications_process!(edited_issues)
    edited_issues.each do |edited_issue|
      unless validate_issues_request?(
          requestor_id: edited_issue[:requestor_id],
          status: edited_issue[:status]
        )
        @error_code = MODIFICATION_ERROR
        return false
      end
      find_modification_request(edited_issue[:id]).update!(
        nonrating_issue_category: edited_issue[:nonrating_issue_category],
        decision_date: edited_issue[:decision_date],
        nonrating_issue_description: edited_issue[:nonrating_issue_description],
        request_reason: edited_issue[:request_reason]
      )
    end

    true
  end

  def canceled_modifications_process!(canceled_issues)
    canceled_issues.each do |canceled_issue|
      unless validate_issues_request?(
        requestor_id: canceled_issue[:requestor_id],
        status: canceled_issue[:status])
        @error_code = MODIFICATION_ERROR
        return false
      end
      find_modification_request(canceled_issue[:id]).update!(status: STATUS[:cancelled])
    end
    true
  end

  def validate_new_issues?(status:)
    STATUS[:assigned] == status.downcase
  end

  def validate_issues_request?(requestor_id:, status:)
    current_user == requestor(requestor_id) && STATUS[:assigned] == status.downcase
  end

  def find_modification_request(id)
    @issue_modification_request = IssueModificationRequest.find(id)
  end

  def requestor(id)
    @requestor = User.find(id)
  end
end

