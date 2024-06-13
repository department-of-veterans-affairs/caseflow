# frozen_string_literal: true

# has issue modification request business login.

class IssueModificationRequests::AdminUpdater
  attr_accessor :user, :review, :issue_modification_requests_data

  def initialize(user:, review:, issue_modification_requests_data:)
    @user = user
    @review = review
    @issue_modification_requests_data = issue_modification_requests_data
  end

  # TODO: See if we can combine the two updater classes into one since they aren't that different.
  # TODO: Adjust this based on the key that is coming in from the UI
  def perform!
    issue_modification_requests_data.each do |issue_modification_request_data|
      # TODO: This isn't safe since it could fail if the id is not correct
      issue_modification_request = IssueModificationRequest.find(issue_modification_request_data[:id])
      update_request(issue_modification_request, issue_modification_request_data)
    end
  end

  private

  def update_request(issue_modification_request, data)
    case data[:status].to_sym
    when :denied
      update_denied_request(issue_modification_request, data)
    when :approved
      update_approved_request(issue_modification_request, data)
    end
  end

  def update_denied_request(issue_modification_request, data)
    issue_modification_request.update!(
      decided_at: Time.zone.now,
      decider: user,
      status: :denied,
      decision_reason: data[:decision_reason]
    )
  end

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
end
