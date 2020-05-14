# frozen_string_literal: true

class VirtualHearings::SendEmail
  attr_reader :virtual_hearing, :type

  def initialize(virtual_hearing:, type:)
    @virtual_hearing = virtual_hearing
    @type = type
  end

  def call
    if !virtual_hearing.veteran_email_sent
      virtual_hearing.update!(veteran_email_sent: send_email(veteran_recipient))
    end

    if should_judge_receive_email?
      virtual_hearing.update!(judge_email_sent: send_email(judge_recipient))
    end

    if !virtual_hearing.representative_email.nil? && !virtual_hearing.representative_email_sent
      virtual_hearing.update!(representative_email_sent: send_email(representative_recipient))
    end
  end

  private

  def email_for_recipient(recipient)
    args = {
      mail_recipient: recipient,
      virtual_hearing: virtual_hearing
    }

    case type.to_s
    when "confirmation"
      VirtualHearingMailer.confirmation(**args)
    when "cancellation"
      VirtualHearingMailer.cancellation(**args)
    when "updated_time_confirmation"
      VirtualHearingMailer.updated_time_confirmation(**args)
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
        app_name: Constants.DATADOG_METRICS.HEARINGS.APP_NAME,
        metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
        metric_name: "emails.submitted"
      )

      Rails.logger.info(
        "[Virtual Hearing: #{virtual_hearing.id}] " \
        "GovDelivery returned (code: #{response.status}) (external url: #{response_external_url})"
      )

      response_external_url
    end
  end
  # :nocov:

  def send_email(recipient)
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
    email = email_for_recipient(recipient)

    return false if email.nil?

    Rails.logger.info("Sending email to #{recipient.inspect}...")

    msg = email.deliver_now!
  rescue StandardError => error
    Rails.logger.warn("Failed to send #{type} email to #{recipient.title}: #{error}")
    Rails.logger.warn(error.backtrace.join($/))

    false
  else
    Rails.logger.info("Sent #{type} email to #{recipient.title}!")

    create_sent_hearing_email_event(recipient, external_message_id(msg))

    true
  end

  # :nocov:
  def create_sent_hearing_email_event(recipient, external_id)
    SentHearingEmailEvent.create!(
      hearing: virtual_hearing.hearing,
      email_type: type,
      email_address: recipient.email,
      external_message_id: external_id,
      recipient_role: recipient.title.downcase,
      sent_by: virtual_hearing.updated_by
    )
  rescue StandardError => error
    Raven.capture_exception(error)
  end
  # :nocov:

  def judge_recipient
    MailRecipient.new(
      name: virtual_hearing.hearing.judge&.full_name,
      email: virtual_hearing.judge_email,
      title: MailRecipient::RECIPIENT_TITLES[:judge]
    )
  end

  def representative_recipient
    MailRecipient.new(
      name: virtual_hearing.hearing.appeal.representative_name,
      email: virtual_hearing.representative_email,
      title: MailRecipient::RECIPIENT_TITLES[:representative]
    )
  end

  def veteran_recipient
    veteran = virtual_hearing.hearing.appeal.veteran

    if veteran.first_name.nil? || veteran.last_name.nil?
      veteran.update_cached_attributes!
    end

    fail "Veteran name is not populated" unless veteran.first_name.present? && veteran.last_name.present?

    MailRecipient.new(
      name: veteran.first_name,
      email: virtual_hearing.veteran_email,
      title: MailRecipient::RECIPIENT_TITLES[:veteran]
    )
  end

  def should_judge_receive_email?
    !virtual_hearing.judge_email.nil? && !virtual_hearing.judge_email_sent && type.to_s != "cancellation"
  end
end
