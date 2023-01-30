#frozen_string_literal: true

class SendMembershipSubmissionConfirmationJob < CaseflowJob
  queue_with_priority :high_priority

  def send_confirmation
    MembershipMailer.membership_request_submitted(recipient_info)
  end

end

