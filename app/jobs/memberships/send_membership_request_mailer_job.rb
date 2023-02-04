#frozen_string_literal: true

class SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(email_type, recipient_info)
    email_to_send(email_type, recipient_info).deliver_now!
  end

  private

  def email_to_send
    case email_type
    when "SendMembershipRequestSubmittedEmail" then MembershipMailer.membership_request_submitted(email_recipient_info: recipient_info)
    when "SendAdminsMembershipSubmissionEmail" then MembershipMailer.membership_request_submission(email_recipient_info: recipient_info)
    when "SendUpdatedMembershipRequestStatusEmail" then MembershipMailer.updated_membership_request_status(email_recipient_info: recipient_info)
    else
      fail ArgumentError, "Unable to send email `#{email_type}`"
    end
  end
end
