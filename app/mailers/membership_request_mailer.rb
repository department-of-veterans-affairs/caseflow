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
  default from: "VHA Benefit Appeals <vhabenefitappeals@messages.va.gov>"
  layout "membership_request_mailer"

  def user_request_created
    @recipient = params[:requestor]
    @requests = params[:requests]
    @requesting_org_names = @requests&.map { |request| request.organization.name }
    @subject = params[:subject]
    mail(to: @recipient&.email, subject: @subject)
  end

  def admin_request_made
    @subject = params[:subject]
    @to = params[:to]
    @organization_name = params[:organization_name]
    mail(to: @to, subject: @subject)
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
