# frozen_string_literal: true

# TODO: Make An abstract MembershipRequestMailBuilder class and inherit from it
# Could also make it not abstract and implement nil methods
class VhaMembershipRequestMailBuilder
  attr_accessor :membership_requests, :requestor

  def initialize(requests)
    @membership_requests = requests
    @requestor = membership_requests.first.requestor
  end

  def send_email_after_creation
    send_requstor_email
    send_organization_emails
  end

  private

  def send_requstor_email
    MembershipRequestMailer.with(recipient_info: requestor,
                                 requests: membership_requests,
                                 subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED)
      .user_request_sent.deliver_now!
  end

  def send_organization_emails
    organizations = membership_requests.map(&:organization)

    organizations.each do |organization|
      send_organization_email(organization)
    end
  end

  def send_organization_email(organization)
    recipient_info = guess_admin(organization)
    # Create an array from the hash and flatten it since some organizations can have two emails
    admin_emails = [get_organization_admin_emails(organization.name)].flatten

    # Send one email to each admin email address
    admin_emails.each do |admin_email|
      MembershipRequestMailer.with(recipient_info: recipient_info,
                                   organization_name: organization.name,
                                   to: admin_email,
                                   subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED)
        .admin_request_made.deliver_now!
    end
  end

  def guess_admin(organization)
    organization.admins.first
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
