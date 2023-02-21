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
  SUBJECT_LINE_VHA_BUSINESSLINE_ADMIN = "You have a new request for access - Do Not Reply"

  # Send requestor a confirmation email that membership request was received.
  def membership_request_submission
    # The vha submission will have two parts an email to the requestor
    # TODO: email to the requestor
    # And an email to the org admin
    # TODO: email to the org/orgs?
    @recipient_info = params[:recipient_info]
    mail(to: @recipient_info[:email], subject: "Membership request submitted.")
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
end
