#frozen_string_literal: true

class SendMembershipStatusUpdateJob < CaseflowJob
  queue_with_priority :high_priority

  def send_status_update
    MembershipMailer.updated_membership_request_status(recipient_info)
  end
end
