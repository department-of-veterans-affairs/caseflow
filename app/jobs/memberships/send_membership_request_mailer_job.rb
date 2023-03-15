# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  LOG_PREFIX = "SendMembershipRequest"

  def perform(email_type, recipient_info)
    MembershipRequestMailer.with(recipient_info: recipient_info).send(
      email_to_send(email_type)
    ).deliver_now!
  end

  private

  def email_to_send(email_type)
    case email_type
    when "SendMembershipRequestSubmittedEmail"
      :membership_request_submitted
    when "SendAdminsMembershipRequestSubmissionEmail"
      :membership_request_submission
    when "SendUpdatedMembershipRequestStatusEmail"
      :updated_membership_request_status
    else
      fail ArgumentError, "Unable to send email `#{email_type}`"
    end
  end

  def external_message_id(msg)
    if msg.is_a?(GovDelivery::TMS::EmailMessage)
      response = msg.response
      response_external_url = response.body.dig("_link", "self")

      DataDogService.increment_counter(\
        app_name: Constants.DATADOG_METRICS.DISPATCH.APP_NAME,
        metric_group: Constants.DATADOG_METRICS.DISPATCH.OUTCODE_GROUP_NAME,
        metric_name: "email.error",
        attrs: {
          email_type: type
        }
      )

      log = log.message.merge(
        status: response.status,
        gov_delivery_id: response_external_url,
        message: "GovDelivery returned (code: #{response.status}) (external url: #{response_external_url})"
      )
      Rails.logger.info("#{LOG_PREFIX} #{log}")

      response_external_url
    end
  end
end
