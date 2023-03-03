# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(email_type, mailer_parameters)
    MembershipRequestMailer.with(mailer_parameters).send(
      email_to_send(email_type)
    ).deliver_now!
  end

  private

  def email_to_send(email_type)
    email_method_mapping_hash = {
      "UserRequestCreated": :user_request_created,
      "AdminRequestMade": :admin_request_made,
      "VhaBusinessLineDenied": :vha_business_line_denied,
      "VhaBusinessLineApproved": :vha_business_line_approved
    }

    method_name = email_method_mapping_hash[email_type&.to_sym]

    fail(ArgumentError, "Unable to send email `#{email_type}`") unless method_name

    method_name
  end
end
