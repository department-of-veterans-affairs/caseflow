# frozen_string_literal: true

class VhaMembershipRequestMailBuilder < MembershipRequestMailBuilder
  attr_accessor :membership_requests, :requestor

  def initialize(requests)
    @membership_requests = [requests].flatten
    @requestor = membership_requests.first.requestor
  end

  def send_email_after_creation
    send_requestor_email
    send_organization_emails
  end

  def send_email_request_approved
    if single_request.requesting_vha_predocket_access?
      send_approved_predocket_organization_email
    else
      send_approved_vha_business_line_email
    end
  end

  def send_email_request_denied
    if single_request.requesting_vha_predocket_access?
      send_denied_predocket_organization_email
    else
      send_denied_vha_business_line_email
    end
  end

  # In cases of an admin user bypassing a user initiated request in favor of the traditional add user functionality
  # We still want to notify the requestor that they've been added to the organization
  def send_email_request_cancelled
    send_email_request_approved
  end

  private

  def send_requestor_email
    mailer_parameters = {
      requestor: requestor,
      requests: membership_requests,
      subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED
    }
    Memberships::SendMembershipRequestMailerJob.perform_later("UserRequestCreated", mailer_parameters)
  end

  def send_organization_emails
    organizations = membership_requests.map(&:organization)

    organizations.each do |organization|
      send_organization_email(organization)
    end
  end

  def send_organization_email(organization)
    org_name = organization.name
    # Create an array from the hash and flatten it since organizations can have multiple emails
    # Set the admin emails to the same email address in UAT for testing
    admin_emails = if Rails.deploy_env?(:uat)
                     ["BID_Appeals_UAT@bah.com"]
                   else
                     [get_organization_admin_emails(org_name)].flatten
                   end

    mailer_parameters = {
      organization_name: org_name,
      subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED
    }

    # Send one email to each admin email address
    admin_emails.each do |admin_email|
      Memberships::SendMembershipRequestMailerJob.perform_later("AdminRequestMade",
                                                                mailer_parameters.merge(to: admin_email))
    end
  end

  def send_approved_vha_business_line_email
    mailer_parameters = {
      requestor: requestor,
      accessible_groups: requestor_accessible_org_names,
      organization_name: single_request.organization.name,
      pending_organization_request_names: requestor_vha_pending_organization_request_names
    }
    Memberships::SendMembershipRequestMailerJob.perform_later("VhaBusinessLineApproved",
                                                              mailer_parameters)
  end

  def send_approved_predocket_organization_email
    mailer_parameters = {
      requestor: requestor,
      accessible_groups: requestor_accessible_org_names,
      organization_name: single_request.organization.name,
      pending_organization_request_names: requestor_vha_pending_organization_request_names
    }
    Memberships::SendMembershipRequestMailerJob.perform_later("VhaPredocketApproved",
                                                              mailer_parameters)
  end

  def send_denied_vha_business_line_email
    mailer_parameters = {
      requestor: requestor,
      accessible_groups: requestor_accessible_org_names,
      organization_name: single_request.organization.name,
      pending_organization_request_names: requestor_vha_pending_organization_request_names
    }
    Memberships::SendMembershipRequestMailerJob.perform_later("VhaBusinessLineDenied",
                                                              mailer_parameters)
  end

  def send_denied_predocket_organization_email
    mailer_parameters = {
      requestor: requestor,
      accessible_groups: requestor_accessible_org_names,
      organization_name: single_request.organization.name,
      pending_organization_request_names: requestor_vha_pending_organization_request_names,
      has_vha_access: belongs_to_vha_org?
    }
    Memberships::SendMembershipRequestMailerJob.perform_later("VhaPredocketDenied",
                                                              mailer_parameters)
  end

  def requestor_accessible_org_names
    @requestor_accessible_org_names ||= requestor.organizations.map(&:name)
  end

  def requestor_vha_pending_organization_request_names
    pending_names = requestor.membership_requests.assigned.includes(:organization).map do |request|
      organization = request.organization
      if organization_vha?(organization)
        organization.name
      end
    end
    pending_names.compact
  end

  def organization_vha?(organization)
    vha_organization_types = [VhaBusinessLine, VhaCamo, VhaCaregiverSupport, VhaProgramOffice, VhaRegionalOffice]
    vha_organization_types.any? { |vha_org| organization.is_a?(vha_org) }
  end

  def belongs_to_vha_org?
    # requestor.organizations.any? { |org| org.url == "vha" }
    requestor.member_of_organization?(VhaBusinessLine.singleton)
  end

  def single_request
    @single_request ||= membership_requests.first
  end

  def get_organization_admin_emails(organization_name)
    {
      "Veterans Health Administration": COPY::VHA_BENEFIT_EMAIL_ADDRESS,
      "VHA CAMO": COPY::VHA_BENEFIT_EMAIL_ADDRESS,
      "VHA Caregiver Support Program": COPY::VHA_CAREGIVER_SUPPORT_EMAIL_ADDRESS,
      "Community Care - Veteran and Family Members Program": COPY::VHA_VETERAN_AND_FAMILY_MEMBERS_EMAIL_ADDRESS,
      "Community Care - Payment Operations Management": COPY::VHA_PAYMENT_OPERATIONS_EMAIL_ADDRESS,
      "Member Services - Health Eligibility Center": [
        COPY::VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_EMAIL_ADDRESS_1,
        COPY::VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_EMAIL_ADDRESS_2
      ],
      "Member Services - Beneficiary Travel": COPY::VHA_MEMBER_SERVICES_BENEFICIARY_TRAVEL_EMAIL_ADDRESS,
      "Prosthetics": COPY::VHA_PROSTHETICS_EMAIL_ADDRESS
    }[organization_name.to_sym]
  end
end
