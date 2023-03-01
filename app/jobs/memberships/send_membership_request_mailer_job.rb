# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(email_type, mailer_parameters)
    MembershipRequestMailer.with(mailer_parameters).send(
      email_to_send(email_type)
    ).deliver_now!
  end

  private

  # def email_to_send(email_type)
  #   case email_type
  #   when "SendMembershipRequestSubmittedEmail"
  #     :membership_request_submitted
  #   when "SendAdminsMembershipRequestSubmissionEmail"
  #     :membership_request_submission
  #   when "SendUpdatedMembershipRequestStatusEmail"
  #     :updated_membership_request_status
  #   when "UserRequestCreated"
  #     :user_request_created
  #   when "AdminRequestMade"
  #   else
  #     fail ArgumentError, "Unable to send email `#{email_type}`"
  #   end
  # end

  def email_to_send(email_type)
    # puts "can I see this?"
    # puts email_type.inspec
    email_method_mapping_hash = {
      "UserRequestCreated": :user_request_created,
      "AdminRequestMade": :admin_request_made
    }

    email_method_mapping_hash[email_type.to_sym]
  end
end
