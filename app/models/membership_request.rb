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
    def send_creation_emails(requests)
      # TODO: should this be a method on the Org class? that defines the mailer class to use?
      NewMailer.create_emails(requests)
    end
  end
  ############################################################################################
end
