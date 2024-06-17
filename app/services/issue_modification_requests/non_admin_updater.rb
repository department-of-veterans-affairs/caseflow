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

    # TODO: Redo this a bit since the two updaters are combined and need to work with the same controller logic
    new_modifications_process!(issue_modifications_data[:new])
    edited_modifications_process!(issue_modifications_data[:edited])
    cancelled_modifications_process!(issue_modifications_data[:cancelled])

    process_admin_decisions(issue_modifications_data[:decided])
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

  def process_admin_decisions(decided_issue_modification_requests)
    decided_issue_modification_requests.each do |decided_request|
      # TODO: Unsafe, but should exist
      issue_modification_request = IssueModificationRequest.find(decided_request[:id])
      update_request(issue_modification_request, issue_modification_request_data)
    end
  end

  def update_request(issue_modification_request, data)
    case data[:status].to_sym
    when :denied
      update_denied_request(issue_modification_request, data)
    when :approved
      update_approved_request(issue_modification_request, data)
    end
  end

  # TODO: Move this logic into the IssueModificationRequest model class
  def update_denied_request(issue_modification_request, data)
    # TODO: I think this can also update some of the fields in the models, but I don't know which ones maybe all
    issue_modification_request.update!(
      decided_at: Time.zone.now,
      decider: user,
      status: :denied,
      decision_reason: data[:decision_reason]
    )
  end

  # TODO: Move this logic into the IssueModificationRequest model class
  def update_approved_request(issue_modification_request, data)
    common_updates = {
      decider: user,
      decided_at: Time.zone.now,
      status: data[:status]
    }

    # TODO: Also update some of the other params that the admin can update here
    specific_updates = case data[:request_type]&.to_sym
                       when :withdrawal, :removal, :addition
                         {}
                       when :modification
                         { remove_original_issue: data[:remove_original_issue] }
                       else
                         fail "Unknown request type: #{issue_modification_request.request_type}"
                       end

    issue_modification_request.update!(common_updates.merge(specific_updates))
  end

  def process_modification?
    issue_modifications_data.present? && (
      issue_modifications_data[:cancelled].any? ||
      issue_modifications_data[:edited].any? ||
      issue_modifications_data[:new].any? ||
      issue_modifications_data[:decided].any?
    )
  end
end
