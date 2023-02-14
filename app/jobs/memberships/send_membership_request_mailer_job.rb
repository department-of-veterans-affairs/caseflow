# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  def initialize(email_type, recipient_info)
    @email_type = email_type
    @mailer = MembershipRequestMailer.with(recipient_info: recipient_info)
  end

  def perform
    email_to_send.deliver_now!
  end

  def email_to_send
    case @email_type
    when
      "SendMembershipRequestSubmittedEmail"
      @mailer.membership_request_submitted
    when
      "SendAdminsMembershipRequestSubmissionEmail"
      @mailer.membership_request_submission
    when
      "SendUpdatedMembershipRequestStatusEmail"
      @mailer.updated_membership_request_status
    else
      fail ArgumentError, "Unable to send email `#{@email_type}`"
    end
  end
end
