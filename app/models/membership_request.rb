# frozen_string_literal: true

class MembershipRequest < CaseflowRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :organization, :requestor, presence: true
  validates :status, uniqueness: { scope: [:organization_id, :requestor_id], if: :assigned? }

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
end
