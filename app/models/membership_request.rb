# frozen_string_literal: true

class MembershipRequest < CaseflowRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :organization, :requestor, presence: true

  # TODO: Do we want a uniqueness validation for status of assigned, organization, and requestor?

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  ############################################################################################
  ## class methods
  class << self
    # TODO: Need to put a guard on this to make sure that they aren't a member of the organization already
    # TODO: Also need to put a guard on it to make sure they don't already have a pending request to that org.
    def create_many_from_orgs(organizations, params, user)
      # puts "in create many from orgs"
      # puts "user: #{user.inspect}"
      # puts "organizations: #{organizations}"
      # TODO: might need to compact this if one fails?
      created_requests = organizations.map do |org|
        create!(
          organization: org,
          requestor: user,
          note: params[:requestReason]
        )
      end
      created_requests
    end

    # Need a seperate method in case an org would want to create requests without emailing.
    # TODO: Need to make this generic somehow
    # TODO: Maybe only send params? or maybe
    def create_many_from_params_and_send_creation_emails(organizations, params, user)
      created_requests = create_many_from_orgs(organizations, params, user)
      # send_creation_emails(created_requests)
      created_requests
    end

    # TODO: Need a method to decide which emails to send and it needs a mapper class/object somehow to avoid being
    # Specific to VHA. This is actually going to be a bit tricky
    # TODO: Do you need to send user? Probably not since the requests know the requestor
    def send_creation_emails(membership_requests, org_type = "VHA")
      # TODO: should this be a method on the Org class? that defines the mailer class to use?
      # Old attempt with MailerFactory
      # MembershipRequestMailerFactory.get_mailer(org_type)
      #   .with(requestor: user, requests: requests)
      #   .membership_request_submission

      MembershipRequestMailBuilderFactory.get_builder(org_type).new(membership_requests).send_email_after_creation
    end
  end
  ############################################################################################
end
