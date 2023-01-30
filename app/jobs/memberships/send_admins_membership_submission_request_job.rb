#frozen_string_literal: true

class SendAdminsMembershipSubmissionJob < CaseflowJob
  queue_with_priority :high_priority

  def send_status_update
    MembershipMailer.membership_request_submission(recipient_info)
  end
end
