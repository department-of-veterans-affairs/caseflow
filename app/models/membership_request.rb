# frozen_string_literal: true

class MembershipRequest < CaseflowRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :organization, :requestor, presence: true
  validates :status, uniqueness: { scope: [:organization_id, :requestor_id], if: :assigned? }

  before_save :set_decided_at

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  ############################################################################################
  ## class methods
  class << self
    def create_many_from_orgs(organizations, params, user)
      created_requests = organizations.map do |org|
        # Skip creating this request if the user is already a member of the Organization
        next if user.member_of_organization?(org)

        create!(
          organization: org,
          requestor: user,
          note: params[:requestReason]
        )
      end
      created_requests.compact
    end

    def create_many_from_params_and_send_creation_emails(organizations, params, user)
      created_requests = create_many_from_orgs(organizations, params, user)
      # Only send emails if there are created requests.
      if created_requests.present?
        send_creation_emails(created_requests)
      end
      created_requests
    end

    def send_creation_emails(membership_requests, org_type = "VHA")
      MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(membership_requests).send_email_after_creation
    end
  end
  ############################################################################################

  def update_status_and_send_email(new_status, deciding_user, org_type = "VHA")
    update!(status: new_status, decider: deciding_user)

    mailer_method = if approved?
                      organization.add_user(requestor)
                      # If the User is requesting VHA sub organization access, also add them to the VHA Businessline
                      check_request_for_automatic_addition_to_vha_businessline(deciding_user)
                      :send_email_request_approved
                    elsif denied?
                      :send_email_request_denied
                    elsif cancelled?
                      # If the User is cancelling a VHA sub organization request, also add them to the VHA Businessline
                      # This is typically triggered using the add_user functionality on a team management page
                      check_request_for_automatic_addition_to_vha_businessline(deciding_user)
                      :send_email_request_cancelled
                    end
    MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(self).send(mailer_method)
  end

  def requesting_vha_predocket_access?
    vha_organization_types = [VhaCamo, VhaCaregiverSupport, VhaProgramOffice, VhaRegionalOffice]
    vha_organization_types.any? { |vha_org| organization.is_a?(vha_org) }
  end

  def check_request_for_automatic_addition_to_vha_businessline(deciding_user)
    if requesting_vha_predocket_access?
      vha_business_line = BusinessLine.find_by(url: "vha")

      # If the requestor also has an outstanding membership request to the vha_businessline approve it
      # Also send an approval email
      vha_business_line_request = requestor.membership_requests.assigned.find_by(organization: vha_business_line)
      vha_business_line_request&.update_status_and_send_email("approved", deciding_user, "VHA")

      # If the user has not been added to VHA at this point then add it to the business line
      vha_business_line.add_user(requestor)

    end
  end

  private

  def set_decided_at
    if status_changed? && status_was == "assigned" && decider_id?
      self.decided_at = Time.zone.now
    end
  end
end
