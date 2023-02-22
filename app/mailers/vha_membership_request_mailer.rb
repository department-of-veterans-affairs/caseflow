# frozen_string_literal: true

# TODO: Might might an abstract MembershipMailer class? Not sure
class VhaMembershipRequestMailer < MembershipRequestMailer
  default from: "<VHABENEFITAPPEALS@va.gov>"
  # layout :unknown
  # Probably 3 methods corresponding to the MembershipRequestMailer methods

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

  # Send requestor a confirmation email that membership request was received.
  def membership_request_submission
    # The vha submission will have two parts an email to the requestor
    # TODO: email to the requestor
    # And an email to the org admin
    # TODO: email to the org/orgs?
    # @recipient_info = params[:recipient_info]
    # mail(to: @recipient_info[:email], subject: "Membership request submitted.")

    # TODO: enable these when the email templates are added?
    # requestor_subission_email(requestor)
    # send_org_emails(organizations)
  end

  # Send requestor an email with updated status of membership request.
  def updated_membership_request_status
    @recipient_info = params[:recipient_info]
    mail(to: @recipient_info[:email], subject: "Membership request status updated.")
  end

  # Send admins an email when a membership request is successfully submitted
  # def membership_request_submission
  #   @recipient_info = params[:recipient_info]
  #   mail(to: @recipient_info[:email], subject: "New membership request recieved.")
  # end

  private

  def requestor_subission_email(requestor)
    mail(to: requestor.email, subject: SUBJECT_LINE_REQUESTOR_SUBMITTED)
  end

  def send_org_emails(organizations)
    organizations.each do |org|
      organization_email(org)
    end
  end

  # TODO: either reduce this or just disable the warning. Ideally each org would be responsible to definining
  # it's own mail method but whatever. Could also create mini mailers for each org and call them here
  # TODO: also figure out which template gets used?
  # TODO: could also make it a hash. It's probably faster and reduces CC but might be less readable?
  # Might also have to make this all the same method name with the case statement again.
  def organization_email(org)
    case org.name
    when "Veterans Health Administration"
      vha_business_line_email
    when "VHA CAMO"
      vha_camo_email
    when "VHA Caregiver Support Program"
      vha_caregiver_email
    when "Community Care - Veteran and Family Members Program"
      community_care_veteran_and_family_members_email
    when "Community Care - Payment Operations Management"
      community_care_payment_operations_management_email
    when "Member Services - Health Eligibility Center"
      member_services_health_eligibility_center_emails
    when "Member Services - Beneficiary Travel"
      member_services_beneficiary_travel_email
    when "Prosthetics"
      prosthetics_email
    else
      fail Caseflow::Error::InvalidEmailError, message: "#{org.name} is not a valid VHA Predocket organization."
    end
  end

  def vha_business_line_email
    mail(to: VHA_BUSINESSLINE_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def vha_camo_email
    mail(to: VHA_CAMO_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def vha_caregiver_email
    mail(to: VHA_CAREGIVER_SUPPORT_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def community_care_veteran_and_family_members_email
    mail(to: VHA_VETERAN_AND_FAMILY_MEMBERS_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def community_care_payment_operations_management_email
    mail(to: VHA_PAYMENT_OPERATIONS_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def member_services_health_eligibility_center_emails
    mail(to: VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_ADMIN_EMAIL_1,
         subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
    mail(to: VHA_MEMBER_SERVICES_HEALTH_ELIGIBILITY_CENTER_ADMIN_EMAIL_2,
         subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def member_services_beneficiary_travel_email
    mail(to: VHA_MEMBER_SERVICES_BENEFICIARY_TRAVEL_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end

  def prosthetics_email
    mail(to: VHA_PROSTHETICS_ADMIN_EMAIL, subject: SUBJECT_LINE_VHA_ADMIN_REQUEST_SUBMITTED)
  end
end
