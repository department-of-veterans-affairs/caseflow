# frozen_string_literal: true

# has issue modification request business login.

class IssueModificationRequests::AdminUpdater
  def initialize(current_user:, review:, request_issues_update:, issue_modification_responses_data:)
    @current_user = current_user
    @review = review
    @request_issues_update = request_issues_update
    @decisions = issue_modification_responses_data
  end

  attr_accessor :current_user, :review, :decisions

  def perform!

    binding.pry

    decisions.each_value do |values|
      case value[:request_type].to_sym

        # When addition
      when :addition
        # if status=aprroved
          # -> Create RequestIssue based on Request
          # update IssueModificationRequest with decider_id,decided_at, decision_date
        # else status=denied
          # updated IssueModificationRequest with decision_reason, status denied, decider_id, decided_at

      when :modification
        # Validate that the same user is the one editing
         # if status=aprroved
          # -> update RequestIssue based on Request
            # -> if remove_original_issue true -> delete old RequestIssue and created a new one
          # update IssueModificationRequest with decider_id, decided_at, decision_date,
      when :withdrawal
        # Validate that the same user is the one is canceling his own modification
      when :removal
      end
    end
  end

  private

  def request_issue(request_issue_id)
    @request_issue = RequestIssue.find(request_issue_id)
  end

  def requestor(requestor_id)
    requestor || User.find(requestor_id)
  end
end
