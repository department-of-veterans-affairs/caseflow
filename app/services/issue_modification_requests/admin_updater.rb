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

    decisions.each_value do |value|
      issue_modification_request = IssueModificationRequest.find(value[:id])
      case issue_modification_request.request_type.to_sym

        # When addition
      when :addition
        if value[:status] == 'approved'
          # -> Create RequestIssue based on Request
          # update IssueModificationRequest with decider_id,decided_at, decision_date
          issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            request_issue_id: value[:request_issue_id], # need to figure out how to update request_issue_id after request issue is created
            decision_date: value[:decision_date],
            nonrating_issue_category: value[:nonrating_issue_category],
            nonrating_issue_description: value[:nonrating_issue_description],
            request_reason: value[:request_reason],
            status: value[:status]
          )
        # else status=denied
        else
          # updated IssueModificationRequest with decision_reason, status denied, decider_id, decided_at
          issue_modification_request.update!(
            decision_reason: value[:decision_reason],
            decider_id: current_user,
            decided_at: Time.zone.now,
            decision_date: value[:decision_date],
            nonrating_issue_category: value[:nonrating_issue_category],
            nonrating_issue_description: value[:nonrating_issue_description],
            request_reason: value[:request_reason],
            status: value[:status]
          )
        end

      when :modification
        # -> update RequestIssue based on Request
        if value[:status] == 'approved'
          if value[:remove_original_issue] == false
            issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            request_issue_id: value[:request_issue_id], # need to figure out how to update request_issue_id after request issue is created
            decision_date: value[:decision_date],
            nonrating_issue_category: value[:nonrating_issue_category],
            nonrating_issue_description: value[:nonrating_issue_description],
            request_reason: value[:request_reason],
            status: value[:status]
          )
          # -> if remove_original_issue true -> delete old RequestIssue and created a new one
          else
            request_issue = RequestIssue.find(value[:request_issue_id])
            request_issue.delete
            new_request_issue = {
              nonrating_issue_category: value[:nonrating_issue_category],
              nonrating_issue_description: value[:nonrating_issue_description],
              decision_date: value[:decision_date],
              benefit_type: 'vha',
              decision_review: review,
            }
            issue_modification_request.create_request_issue(new_request_issue)
          end
          # update IssueModificationRequest with decider_id, decided_at, decision_date,
        else
          issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            decision_reason: value[:decision_reason],
            decision_date: value[:decision_date],
            nonrating_issue_category: value[:nonrating_issue_category],
            nonrating_issue_description: value[:nonrating_issue_description],
            request_reason: value[:request_reason],
            status: value[:status]
          )
        end
      when :withdrawal
        if value[:status] == 'approved'
          issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            decision_date: value[:decision_date],
            request_reason: value[:request_reason],
            withdrawal_date: value[:withdrawal_date],
            status: value[:status]
          )
          # RequestIssue.find(value[:request_issue_id]).withdraw!(value[:withdrawal_date])
        else
          issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            decision_date: value[:decision_date],
            request_reason: value[:request_reason],
            status: value[:status],
            decision_reason: value[:decision_reason]
          )
        end
      when :removal
        if value[:status] == 'approved'
          issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            request_reason: value[:request_reason],
            status: value[:status]
          )
          # RequestIssue.find(value[:request_issue_id]).remove!
        else
          issue_modification_request.update!(
            decider_id: current_user,
            decided_at: Time.zone.now,
            request_reason: value[:request_reason],
            status: value[:status],
            decision_reason: value[:status]
          )
        end
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
