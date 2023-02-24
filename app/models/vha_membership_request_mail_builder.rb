# frozen_string_literal: true

# TODO: Make An abstract MembershipRequestMailBuilder class and inherit from it
# Could also make it not abstract and implement nil methods
class VhaMembershipRequestMailBuilder
  attr_accessor :membership_requests, :requestor

  # TODO: Move these into a constants file somewhere
  SUBJECT_LINE_REQUESTOR_SUBMITTED = "Request recieved - Do Not Reply"
  SUBJECT_LINE_REQUESTOR_APPROVED = "Request approved - Do Not Reply"
  SUBJECT_LINE_REQUESTOR_DENIED = "Request denied - Do Not Reply"
  SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED = "You have a new request for access - Do Not Reply"

  # TODO: Move admin emails into a constants file somewhere
  VHA_BUSINESSLINE_ADMIN_EMAIL = "VHABENEFITAPPEALS@va.gov"
  VHA_CAMO_ADMIN_EMAIL = "VHABENEFITAPPEALS@va.gov"
  VHA_CAREGIVER_SUPPORT_ADMIN_EMAIL = "VHA.CSPAppeals@va.gov"
  VHA_PAYMENT_OPERATIONS_ADMIN_EMAIL = "VHA10D1B3R2Appeals@va.gov"
  VHA_VETERAN_AND_FAMILY_MEMBERS_ADMIN_EMAIL = "VHA16IVCAppealsHighLevelCorrespondence@va.gov"
  VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_ADMIN_EMAIL_1 = "HECIVDMgt@va.gov"
  VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_ADMIN_EMAIL_2 = "VHAHECMSEEDApealsTeam@va.gov"
  VHA_MEMBER_SERVICES_BENEFICIARY_TRAVEL_ADMIN_EMAIL = "VHAMSBTAppeals@va.gov"
  VHA_PROSTHETICS_ADMIN_EMAIL = "VHAPSASBenefits@va.gov"

  def initialize(requests)
    @membership_requests = requests
    # puts "new_requests: #{new_requests}"
    @requestor = membership_requests.first.requestor
  end

  # TODO: I Don't know if these should be class methods or not
  # It should probably be instance methods if there is logic that needs to be done on the requests array
  def send_email_after_creation
    send_requstor_email
    # MembershipRequestMailer.with(requestor: user, requests: user.membership_requests).request_received.deliver
    send_organization_emails
    # MembershipRequestMailer.admin_request.deliver
  end

  private

  def send_requstor_email
    # @recipient_info = params[:recipient_info]
    MembershipRequestMailer.with(recipient_info: requestor,
                                 requests: membership_requests,
                                 subject: SUBJECT_LINE_REQUESTOR_SUBMITTED)
      .request_received.deliver_now!
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
                                   subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
        .admin_request.deliver_now!
    end
  end

  def guess_admin(organization)
    organization.admins.first
  end

  def get_organization_admin_emails(organization_name)
    {
      "Veterans Health Administration": VHA_BUSINESSLINE_ADMIN_EMAIL,
      "VHA CAMO": VHA_CAMO_ADMIN_EMAIL,
      "VHA Caregiver Support Program": VHA_CAREGIVER_SUPPORT_ADMIN_EMAIL,
      "Community Care - Veteran and Family Members Program": VHA_VETERAN_AND_FAMILY_MEMBERS_ADMIN_EMAIL,
      "Community Care - Payment Operations Management": VHA_PAYMENT_OPERATIONS_ADMIN_EMAIL,
      "Member Services - Health Eligibility Center": [VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_ADMIN_EMAIL_1,
                                                      VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_ADMIN_EMAIL_2],
      "Member Services - Beneficiary Travel": VHA_MEMBER_SERVICES_BENEFICIARY_TRAVEL_ADMIN_EMAIL,
      "Prosthetics": VHA_PROSTHETICS_ADMIN_EMAIL
    }[organization_name.to_sym]
  end
end
