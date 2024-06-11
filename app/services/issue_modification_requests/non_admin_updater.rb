# frozen_string_literal: true

# has issue modification request business logic.

# :reek:TooManyInstanceVariables
class IssueModificationRequests::NonAdminUpdater
  attr_accessor :current_user,
                :review,
                :issue_modifications_data

  def initialize(current_user:, review:, issue_modifications_data:)
    @current_user = current_user
    @review = review
    @issue_modifications_data = issue_modifications_data
  end

  def process!
    return false if !process_modification?

    new_modifications_process!(issue_modifications_data[:new])
    edited_modifications_process!(issue_modifications_data[:edited])
    cancelled_modifications_process!(issue_modifications_data[:cancelled])

    # approval_process!(issue_modifications_data[:approval])
    # process_denial!(issue_modifications_data[:denial])
  end

  private

  def new_modifications_process!(new_issues)
    new_issues.each do |new_issue|
      IssueModificationRequest.create_from_params!(new_issue, review, current_user)
    end
    true
  end

  def edited_modifications_process!(edited_issues)
    edited_issues.each do |edited_issue|
      issue_modification_request = IssueModificationRequest.find(edited_issue[:id])

      issue_modification_request.edit_from_params!(edited_issue, current_user)
    end

    true
  end

  def cancelled_modifications_process!(cancelled_issues)
    cancelled_issues.each do |cancelled_issue|
      issue_modification_request = IssueModificationRequest.find(cancelled_issue[:id])

      issue_modification_request.cancel_from_params!(cancelled_issue, current_user)
    end
    true
  end

  def process_modification?
    issue_modifications_data.present? && (
      issue_modifications_data[:cancelled].any? ||
      issue_modifications_data[:edited].any? ||
      issue_modifications_data[:new].any?
    )
  end
end
