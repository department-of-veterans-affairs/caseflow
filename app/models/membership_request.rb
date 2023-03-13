# frozen_string_literal: true

class MembershipRequest < ApplicationRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :organization, :requestor, presence: true

  before_save :set_decided_at

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  def update_status_and_send_email(new_status, user, org_type = "VHA")
    # TODO: Might need to wrap this in a transaction and if adding the user to the org fails roll it back?
    # TODO: Enable this again after testing email
    update(status: new_status, decider: user)
    # TODO: If the status is approved then add the user to the org
    # TODO: Should this be a callback hook like after_update or should it just be done here
    # membership_request_mailer_params = {}
    if approved?
      # TODO: If the request is to a predocket and the user is not already a member of VHA add them to VHA
      # TODO: Also this will change the email as well
      # MembershipRequestMailer.with().vha_businessline_approval.deliver_now!

      # Add user will automatically find the record or create it so there is no need for
      # An additional check if they are already a member of the org
      organization.add_user(requestor)

      # MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(self).send_email_request_approved

      # mail_type = ""
      # mail_params = { requestor: requestor }
      # If the organization is a VHA predocket organization also add the user to the Vha BusinessLine
      if requesting_vha_predocket_access?
        vha_business_line = BusinessLine.find_by(url: "vha")

        vha_business_line.add_user(requestor)
        # mail_type = ""
        # mail_params = {}
      end

      MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(self).send_email_request_approved

      # TODO: Ask if this should be any orgs or just VHA orgs?
      # TODO: Move this stuff into the builder
      # accessible_orgs = requestor.organizations.map(&:name)
      # if requesting_vha_predocket_access?
      #   mailer_params = {
      #     requestor: requestor,
      #     accessible_groups: accessible_orgs,
      #     organization_name: organization.name,
      #     pending_organization_request_names: pending_organization_request_names
      #   }
      #   # puts mailer_params.inspect
      #   MembershipRequestMailer.with(mailer_params)
      #     .vha_predocket_organization_approved.deliver_now!
      # else
      #   MembershipRequestMailer.with(requestor: requestor, accessible_groups: accessible_orgs)
      #     .vha_business_line_approved.deliver_now!
      # end

    elsif denied?
      # accessible_orgs = requestor.organizations.map(&:name)
      # if requesting_vha_predocket_access?
      #   mailer_params = {
      #     requestor: requestor,
      #     accessible_groups: accessible_orgs,
      #     organization_name: organization.name,
      #     pending_organization_request_names: pending_organization_request_names
      #   }
      #   MembershipRequestMailer.with(mailer_params)
      #     .vha_predocket_organization_denied.deliver_now!
      # else
      #   MembershipRequestMailer.with(requestor: requestor, accessible_groups: accessible_orgs)
      #     .vha_business_line_denied.deliver_now!
      # end
      MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(self).send_email_request_denied

    end
    # accessible_orgs = requestor.organizations.map(&:name)
    # MembershipRequestMailer.with(requestor: requestor, accessible_groups: accessible_orgs).vha_business_line_denial.deliver_now!
    # Send the email either way
    # MembershipRequestMailBuilderFactory.get_mail_builder(org_type).new(membership_requests).send_email_after_creation
    # TODO: Passdown org type from the submission somehow based on the org? Or derive it?
  end

  def requesting_vha_predocket_access?
    # TODO: Does this need VhaRegionalOffice?
    vha_organization_types = [VhaCamo, VhaCaregiverSupport, VhaProgramOffice, VhaRegionalOffice]
    vha_organization_types.any? { |vha_org| organization.is_a?(vha_org) }
  end

  private

  def set_decided_at
    # TODO: Figure out exactly when to update the decided at time? Should it require a decider?
    # Or should it only care  when the status changes
    if status_changed? && status_was == "assigned" && decider_id?
      self.decided_at = Time.zone.now
    end
  end
end
