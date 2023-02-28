# frozen_string_literal: true

class MembershipRequest < ApplicationRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :organization, :requestor, presence: true

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  def update_status_and_send_email(new_status)
    # TODO: Might need to wrap this in a transaction and if adding the user to the org fails roll it back?
    # TODO: Enable this again after testing email
    # update(status: new_status)
    # TODO: If the status is approved then add the user to the org
    # TODO: Should this be a callback hook like after_update or should it just be done here
    if approved?
      # Add the user to the org
      # TODO: If the request is to a predocket and the user is not already a member of VHA add them to VHA
      # TODO: Also this will change the email as well
      MembershipRequestMailer.with().vha_businessline_approval.deliver_now!
    elsif denied?
      MembershipRequestMailer.with().vha_businessline_denial.deliver_now!
    end
    # Send the email either way
    # MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(membership_requests).send_email_after_creation
    accessible_orgs = requestor.organizations
    MembershipRequestMailer.with(requestor: requestor, accessible_groups: accessible_orgs)
      .vha_business_line_approval.deliver_now!
  end
end
