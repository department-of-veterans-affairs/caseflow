# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  LOG_PREFIX = "SendMembershipRequest"
  TYPE_LABEL = "Send Membership Request notification email"

  def perform(email_type, recipient_info)
    # send_email(email_for_recipient(email_type, recipient_info))
    send_email(
      MembershipRequestMailer.with(recipient_info: recipient_info).send(
        email_to_send(email_type)
      )
    )
  end

  private

  def email_for_recipient(recipient_info, email_type)
    MembershipRequestMailer.with(recipient_info: recipient_info).send(
      email_to_send(email_type)
    )
  end

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

      log = log_message.merge(
        status: response.status,
        gov_delivery_id: response_external_url,
        message: "GovDelivery returned (code: #{response.status}) (external url: #{response_external_url})"
      )
      Rails.logger.info("#{LOG_PREFIX} #{log}")

      response_external_url
    end
  end

  def send_email(email)
    if email.nil?
      log = log_message.merge(status: "error", message: "No #{TYPE_LABEL} was sent because no email address is defined")
      Rails.logger.info("#{LOG_PREFIX} #{log}")
      return false
    end

    log = log_message.merge(status: "info", message: "Sending #{TYPE_LABEL} to #{recipient_info} ...")
    Rails.logger.info("#{LOG_PREFIX} #{log}")
    msg = email.deliver_now!
  rescue StandardError,Savon::Error, BGS::ShareError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS endpoints\
    Raven.capture_exception(error)
    log = log_message.merge(status: "error", message: "Failed to send #{TYPE_LABEL} to #{recipient_info} : #{error}")
    Rails.logger.warn("#{LOG_PREFIX} #{log}")
    Rails.logger.warn(error.backtrace.join($INPUT_RECORD_SEPARATOR))
    false
  else
    message_id = external_message_id(msg)
    message = "Requested GovDelivery to send #{TYPE_LABEL} to #{recipient_info} - #{message_id}"
    log = log_message.merge(status: "success", gov_delivery_id: message_id, message: message)
    Rails.logger.info("#{LOG_PREFIX} #{log}")
    true
  end

  def log_message
    {
      class: self.class,
      appeal_id: @appeal.id,
      recipient_info: @recipient_info,
      email_type: @email_type
    }
  end
end
