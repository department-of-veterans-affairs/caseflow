#frozen_string_literal: true

class SendMembershipMailerJob < CaseflowJob
  queue_with_priority :high_priority

  def initialize(email_type, recipient_info)
    @email_type = email_type
    @recipient_info = recipient_info
  end

  def perform
    email_to_send.deliver_now!
  end

  private

  def email_to_send
    case @email_type
    when "SendMembershipRequestSubmittedEmail" then MembershipMailer.membership_request_submitted(@recipient_info)
    when "SendAdminsMembershipSubmissionEmail" then MembershipMailer.membership_request_submission(@recipient_info)
    when "SendUpdatedMembershipRequestStatusEmail" then MembershipMailer.updated_membership_request_status(@recipient_info)
    else
      fail ArgumentError, "Unable to send email `#{@email_type}`"
    end
  end
end
