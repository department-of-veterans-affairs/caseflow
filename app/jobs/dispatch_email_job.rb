# frozen_string_literal: true

##
# DispatchEmailJob will:
# - Call the GovDelivery API for each EmailRecipient and email combination.
#
# It is used to send the emails that DispatchMailer generates from templates in
# app/views/dispatch_mailer
##
class DispatchEmailJob < CaseflowJob
  attr_reader :appeal, :type, :email_address

  LOG_PREFIX = "BVADispatchEmail"
  TYPE_LABEL = "BVA Dispatch POA notification email"

  def initialize(appeal: nil, type:, email_address:)
    @appeal = appeal
    @type = type.to_s
    @email_address = email_address.to_s
  end

  def call
    send_email(email_for_recipient)
  end

  private

  def email_for_recipient
    case type
    when "dispatch"
      DispatchMailer.dispatch(email_address: email_address, appeal: appeal)
    else
      fail ArgumentError, "Invalid type of email to send: `#{type}`"
    end
  end

  # :nocov:
  def external_message_id(msg)
    if msg.is_a?(GovDelivery::TMS::EmailMessage)
      response = msg.response
      response_external_url = response.body.dig("_links", "self")

      DataDogService.increment_counter(
        app_name: Constants.DATADOG_METRICS.DISPATCH.APP_NAME,
        metric_group: Constants.DATADOG_METRICS.DISPATCH.OUTCODE_GROUP_NAME,
        metric_name: "email.sent",
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
  # :nocov:

  def send_email(email)
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
    if email.nil?
      log = log_message.merge(status: "error", message: "No #{TYPE_LABEL} was sent because no email address is defined")
      Rails.logger.info("#{LOG_PREFIX} #{log}")
      return false
    end

    log = log_message.merge(status: "info", message: "Sending #{TYPE_LABEL} to #{email_address} ...")
    Rails.logger.info("#{LOG_PREFIX} #{log}")
    msg = email.deliver_now!
  rescue StandardError, Savon::Error, BGS::ShareError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS endpoints
    Raven.capture_exception(error)
    log = log_message.merge(status: "error", message: "Failed to send #{TYPE_LABEL} to #{email_address} : #{error}")
    Rails.logger.warn("#{LOG_PREFIX} #{log}")
    Rails.logger.warn(error.backtrace.join($INPUT_RECORD_SEPARATOR))
    false
  else
    message_id = external_message_id(msg)
    message = "Requested GovDelivery to send #{TYPE_LABEL} to #{email_address} - #{message_id}"
    log = log_message.merge(status: "success", gov_delivery_id: message_id, message: message)
    Rails.logger.info("#{LOG_PREFIX} #{log}")
    true
  end

  def log_message
    {
      class: self.class,
      appeal_id: @appeal.id,
      email_address: @email_address,
      email_type: @type
    }
  end
end
