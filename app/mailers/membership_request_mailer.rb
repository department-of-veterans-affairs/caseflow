# frozen_string_literal: true

##
# MembershipRequestMailer will:
# - Handle the selection of email templates
# - Creation of job(s) to handle respective email notification scenarios including:
# - Notify requestor upon successful membership request submission
# - Notify requestor upon change of status of membership request
# - Notify admins upon successful membership request submission

class MembershipRequestMailer < ActionMailer::Base
  default from: "VHABENEFITAPPEALS@va.gov"
  layout "membership_request_mailer"

  # Send requestor a confirmation email that membership request was received.
  def membership_request_submitted
    @requestor = params[:requestor]
    mail(to: @requestor.email, subject: "Membership request submitted.")
  end

  # Send requestor an email with updated status of membership request.
  def updated_membership_request_status
    @recipient_info = params[:recipient_info]
    mail(to: @recipient_info[:email], subject: "Membership request status updated.")
  end

  # Send admins an email when a membership request is successfully submitted
  def membership_request_submission
    @recipient_info = params[:recipient_info]
    mail(to: @recipient_info[:email], subject: "New membership request recieved.")
  end

  # New methods with the email templates
  # TODO: rename this to be more descriptive of the email being sent to the requestor
  def user_request_sent
    @recipient_info = params[:recipient_info]
    @requests = params[:requests]
    @requesting_org_names = @requests&.map { |request| request.organization.name }
    @subject = params[:subject]
    mail(to: @recipient_info&.email, subject: @subject)
  end

  def admin_request_made
    # TODO: how the heck do you get the admin name?
    # Could potentially do organization.admins.first but idk if that's the best way
    @recipient_info = params[:recipient_info]
    @subject = params[:subject]
    @to = params[:to]
    # puts "to address is: #{@to}"
    @organization_name = params[:organization_name]
    mail(to: @to, subject: @subject)
  end
end
