# frozen_string_literal: true

# has issue modification request business logic.

class IssueModificationRequests::Updater
  attr_accessor :user,
                :review,
                :issue_modifications_data

  def initialize(user:, review:, issue_modifications_data:)
    @user = user
    @review = review
    @issue_modifications_data = issue_modifications_data
  end

  def non_admin_process!
    return false if !non_admin_actions?

    new_modifications_process!(issue_modifications_data[:new])
    edited_modifications_process!(issue_modifications_data[:edited])
    cancelled_modifications_process!(issue_modifications_data[:cancelled])
  end

  def admin_process!
    return unless admin_actions?

    process_admin_decisions(issue_modifications_data[:decided])
  end

  def non_admin_actions?
    issue_modifications_data.present? && (
      issue_modifications_data[:cancelled].any? ||
      issue_modifications_data[:edited].any? ||
      issue_modifications_data[:new].any?
    )
  end

  def admin_actions?
    issue_modifications_data.present? && issue_modifications_data[:decided].any?
  end

  def admin_approvals?
    issue_modifications_data.present? &&
      issue_modifications_data[:decided].any? &&
      issue_modifications_data[:decided].any? { |issue_mod_data| issue_mod_data[:status].to_sym == :approved }
  end

  private

  def new_modifications_process!(new_issues)
    new_issues.each do |new_issue|
      IssueModificationRequest.create_from_params!(new_issue, review, user)
    end
    true
  end

  def edited_modifications_process!(edited_issues)
    edited_issues.each do |edited_issue_data|
      issue_modification_request = IssueModificationRequest.find(edited_issue_data[:id])

      issue_modification_request.edit_from_params!(edited_issue_data, user)
    end

    true
  end

  def cancelled_modifications_process!(cancelled_issues)
    cancelled_issues.each do |cancelled_issue|
      issue_modification_request = IssueModificationRequest.find(cancelled_issue[:id])

      issue_modification_request.cancel_from_params!(user)
    end
    true
  end

  def process_admin_decisions(decided_issue_modification_requests_data)
    decided_issue_modification_requests_data.each do |decided_request_data|
      issue_modification_request = IssueModificationRequest.find(decided_request_data[:id])
      update_admin_request(issue_modification_request, decided_request_data)
    end
  end

  def update_admin_request(issue_modification_request, data)
    ActiveRecord::Base.transaction do
      case data[:status].to_sym
      when :denied
        issue_modification_request.deny_request_from_params!(data, user)
      when :approved
        issue_modification_request.approve_request_from_params!(data, user)
      end
    end
  end
end
