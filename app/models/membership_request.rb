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
      send_creation_emails(created_requests)
      created_requests
    end

    def send_creation_emails(membership_requests, org_type = "VHA")
      MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(membership_requests).send_email_after_creation
    end
  end
  ############################################################################################

  def update_status_and_send_email(new_status, user, org_type = "VHA")
    # TODO: Might need to wrap this in a transaction and if adding the user to the org fails roll it back?
    update!(status: new_status, decider: user)

    mailer_method = if approved?
                      organization.add_user(requestor)
                      # If the User is requesting VHA sub organization access, also add them to the VHA Businessline
                      if requesting_vha_predocket_access?
                        vha_business_line = BusinessLine.find_by(url: "vha")

                        vha_business_line.add_user(requestor)
                      end
                      :send_email_request_approved
                    elsif denied?
                      :send_email_request_denied
                    elsif cancelled?
                      :send_email_request_cancelled
                    end
    MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(self).send(mailer_method)
  end

  def requesting_vha_predocket_access?
    # TODO: Does this need VhaRegionalOffice as well?
    vha_organization_types = [VhaCamo, VhaCaregiverSupport, VhaProgramOffice, VhaRegionalOffice]
    vha_organization_types.any? { |vha_org| organization.is_a?(vha_org) }
  end

  private

  def set_decided_at
    # TODO: Figure out exactly when to update the decided at time? Should it require a decider?
    # Or should it only care when the status changes
    if status_changed? && status_was == "assigned" && decider_id?
      self.decided_at = Time.zone.now
    end
  end
end
