# frozen_string_literal: true

##
# MembershipRequestMailer will:
# - Handle the selection of email templates
# - Creation of job(s) to handle respective email notification scenarios including:
# - Notify requestor upon successful membership request submission
# - Notify requestor upon change of status of membership request
# - Notify admins upon successful membership request submission

class MembershipRequestMailer < ActionMailer::Base
  helper MembershipRequestHelper
  default from: "VHABENEFITAPPEALS@va.gov"
  layout "membership_request_mailer"

  # Send requestor a confirmation email that membership request was received.
  def membership_request_submitted
    @recipient_info = params[:recipient_info]
    mail(to: @recipient_info[:email], subject: "Membership request submitted.")
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

  def vha_business_line_approved
    @recipient = params[:requestor]
    @accessible_groups = params[:accessible_groups]
    mail(to: @recipient&.email, subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_APPROVED)
  end

  def vha_business_line_denied
    @recipient = params[:requestor]
    @accessible_groups = params[:accessible_groups]
    mail(to: @recipient&.email, subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_DENIED)
  end

  def vha_predocket_organization_approved
    @recipient = params[:requestor]
    @accessible_groups = params[:accessible_groups]
    @requesting_org_name = params[:organization_name]
    @pending_organization_request_names = params[:pending_organization_request_names]
    mail(to: @recipient&.email, subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_APPROVED)
  end

  def vha_predocket_organization_denied
    @recipient = params[:requestor]
    @accessible_groups = params[:accessible_groups]
    @requesting_org_name = params[:organization_name]
    @pending_organization_request_names = params[:pending_organization_request_names]
    @has_vha_access = params[:has_vha_access]
    mail(to: @recipient&.email, subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_DENIED)
  end
end
