# frozen_string_literal: true

##
# MembershipRequestMailer will:
# - Handle the selection of email templates
# - Creation of job(s) to handle respective email notification scenarios including:
# - Notify requestor upon successful membership request submission
# - Notify requestor upon change of status of membership request
# - Notify admins upon successful membership request submission

class MembershipRequestMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "membership_request_mailer"

  # Send requestor a confirmation email that membership request was received.
  def membership_request_submitted(email_recipient_info:, custom_subject: "Membership request submitted.")
    @recipient_info = email_recipient_info
    mail(to: @recipient_info[:email], subject: custom_subject)
  end

  # Send requestor an email with updated status of membership request.
  def updated_membership_request_status(email_recipient_info:, custom_subject: "Membership request status updated.")
    @recipient_info = email_recipient_info
    mail(to: @recipient_info[:email], subject: custom_subject)
  end

  # Send admins an email when a membership request is successfully submitted
  def membership_request_submission(email_recipient_info:, custom_subject: "New membership request recieved.")
    @recipient_info = email_recipient_info
    mail(to: @recipient_info[:email], subject: custom_subject)
  end
end
