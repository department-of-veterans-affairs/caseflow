# frozen_string_literal: true

##
# MembershipMailer will:
# - Handle the selection of email templates
# - Creation of job(s) to handle respective email notification scenarios including:
# - Notify requestor upon successful membership request submission
# - Notify requestor upon change of status of membership request
# - Notify admins upon successful membership request submission

class MembershipMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "dispatch_mailer"
  #helper Membership::

  #Send requestor a confirmation email that membership request was recieved.
  def membership_request_submitted(email_recipient_info:)
    @recipient_info = email_recipient_info
    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

  # Send requestor an email with updated status of membership request.
  def updated_membership_request_status(email_recipient_info:)
    @recipient_info = email_recipient_info
    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

  # Send admins an email when a membership request is successfully submitted
  def membership_request_submission(email_recipient_info:)
    @recipient_info = email_recipient_info
    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

end

