# frozen_string_literal: true

class Memberships::SendMembershipRequestMailerJob < CaseflowJob
  queue_with_priority :low_priority

  LOG_PREFIX = "SendMembershipRequest"
  TYPE_LABEL = "Send Membership Request notification email"

  def perform(email_type, mailer_parameters)
    email_subject = email_to_send(email_type)
    email = MembershipRequestMailer.with(mailer_parameters).send(email_subject)
    send_email(email, mailer_parameters)
  end

  private

  def email_to_send(email_type)
    email_method_mapping_hash = {
      "UserRequestCreated": :user_request_created,
      "AdminRequestMade": :admin_request_made
    }

    method_name = email_method_mapping_hash[email_type&.to_sym]

    fail(ArgumentError, "Unable to send email `#{email_type}`") unless method_name

    method_name
  end

  # :nocov:
  def external_message_id(msg)
    if msg.is_a?(GovDelivery::TMS::EmailMessage)
      response = msg.response
      response_external_url = response.body.dig("_link", "self")

      DataDogService.increment_counter(\
        app_name: Constants.DATADOG_METRICS.VHA.APP_NAME,
        metric_group: Constants.DATADOG_METRICS.VHA.MEMBERSHIP_REQUESTS_GROUP_NAME,
        metric_name: "email.error",
        attrs: {
          recipient_info: mailer_parameters[:recipient_info],
          requests: mailer_parameters[:requests]
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

  def email_nil?(email)
    if email.nil?
      log = log_message(mailer_parameters).merge(
        status: "error", message: "No #{TYPE_LABEL} was sent because no email address is defined"
      )
      Rails.logger.info("#{LOG_PREFIX} #{log}")
      false
    else
      true
    end
  end

  # :nocov:
  def send_email(email, mailer_parameters)
    # Why are we using `deliver_now!`? The documentation mentions that it ignores the flags:
    #
    #   * `perform_deliveries`
    #   * `raise_delivery_errors`
    #
    # https://github.com/mikel/mail/blob/8fbb17d4d5364c77cc870769d451bc2739b3a8ce/lib/mail/message.rb#L261-L272
    #
    # `perform_deliveries` we will always want to be true. There isn't an environment
    # where we wouldn't want to send emails (in the test environment this is already
    # stubbed out).
    #
    # `raise_delivery_errors` we want to be true, but this is the default. This flag
    # is mostly intended if you want to ignore errors when sending emails to invalid
    # email addresses (which we don't want). We want to break flow if GovDelivery
    # returns a non-successful error message, which it should do by default.
    #
    # In summary, ignoring those 2 flags is perfectly fine since we are ok with the
    # default behavior of them both being `true`.
    #
    # The benefit of using `deliver_now!` is that it returns the actual response from
    # GovDelivery. The actual web response gives Caseflow the ability to track
    # the email after it has been accepted by GovDelivery.
    email_nil?(email)

    email_address = mailer_parameters[:recipient_info]
    log = log_message(mailer_parameters).merge(status: "info", message: "Sending #{TYPE_LABEL} to #{email_address} ...")
    Rails.logger.info("#{LOG_PREFIX} #{log}")
    msg = email.deliver_now!
  rescue StandardError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS endpoints\
    Raven.capture_exception(error)
    log = log_message(mailer_parameters).merge(
      status: "error", message: "Failed to send #{TYPE_LABEL} to #{email_address} : #{error}"
    )
    Rails.logger.warn("#{LOG_PREFIX} #{log}")
    Rails.logger.warn(error.backtrace.join($INPUT_RECORD_SEPARATOR))
    false
  else
    message_id = external_message_id(msg)
    message = "Requested GovDelivery to send #{TYPE_LABEL} to #{email_address} - #{message_id}"
    log = log_message(mailer_parameters).merge(status: "success", gov_delivery_id: message_id, message: message)
    Rails.logger.info("#{LOG_PREFIX} #{log}")
    true
  end

  def log_message(mailer_parameters)
    {
      class: self.class,
      recipient_info: mailer_parameters[:recipient_info],
      requests: mailer_parameters[:requests]
    }
  end
end
