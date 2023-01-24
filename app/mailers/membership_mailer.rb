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
  helper Membership::

  def notify_requestor_membership_request_submitted(email_recipient_info:)
    #Should send requestor a confirmation email to that membership request was recieved.
    @recipient_info = email_recipient_info
    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

  def update_requestor_updated_membership_request_status(email_recipient_info:)
    # Should send requestor an email with updated status of membership request.
    @recipient_info = email_recipient_info
    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

  def notify_admins_membership_request_submission(email_recipient_info:)
    # Should send admins an email when a membership request is successfully submitted

    @recipient_info = email_recipient_info
    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

end

