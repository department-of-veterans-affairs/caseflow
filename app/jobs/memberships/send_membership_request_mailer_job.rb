# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(email_type, recipient_info)
    MembershipRequestMailer.with(recipient_info: recipient_info).send(
      email_to_send(email_type)
    ).deliver_now!
  end

  private

  def email_to_send(email_type)
    case email_type
    when "SendMembershipRequestSubmittedEmail"
      :membership_request_submitted
    when "SendAdminsMembershipRequestSubmissionEmail"
      :membership_request_submission
    when "SendUpdatedMembershipRequestStatusEmail"
      :updated_membership_request_status
    else
      fail ArgumentError, "Unable to send email `#{email_type}`"
    end
  end
end
