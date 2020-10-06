# frozen_string_literal: true

class VirtualHearings::SendEmail
  class RecipientIsDeceasedVeteran < StandardError; end

  attr_reader :virtual_hearing, :type

  def initialize(virtual_hearing:, type:)
    @virtual_hearing = virtual_hearing
    @type = type
  end

  def call
    if !virtual_hearing.appellant_email_sent
      virtual_hearing.update!(appellant_email_sent: send_email(appellant_recipient))
    end

    if should_judge_receive_email?
      virtual_hearing.update!(judge_email_sent: send_email(judge_recipient))
    end

    if !virtual_hearing.representative_email.nil? && !virtual_hearing.representative_email_sent
      virtual_hearing.update!(representative_email_sent: send_email(representative_recipient))
    end
  end

  private

  delegate :hearing, to: :virtual_hearing
  delegate :appeal, to: :hearing
  delegate :veteran, to: :appeal

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
  rescue StandardError, Savon::Error, BGS::ShareError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS enpoints
    Raven.capture_exception(error)

    Rails.logger.warn("Failed to send #{type} email to #{recipient.title}: #{error}")
    Rails.logger.warn(error.backtrace.join($INPUT_RECORD_SEPARATOR))

    false
  else
    Rails.logger.info("Sent #{type} email to #{recipient.title}!")

    create_sent_hearing_email_event(recipient, external_message_id(msg))

    true
  end

  # :nocov:
  def create_sent_hearing_email_event(recipient, external_id)
    # The "appellant" title is used in the email and is consistent whether or not the
    # veteran is or isn't the appellant, but the email event can be more specific.
    recipient_is_veteran = (
      recipient.title == MailRecipient::RECIPIENT_TITLES[:appellant] &&
      !appeal.appellant_is_not_veteran
    )
    SentHearingEmailEvent.create!(
      hearing: hearing,
      email_type: type,
      email_address: recipient.email,
      external_message_id: external_id,
      recipient_role: recipient_is_veteran ? "veteran" : recipient.title.downcase,
      sent_by: virtual_hearing.updated_by
    )
  rescue StandardError => error
    Raven.capture_exception(error)
  end
  # :nocov:

  def judge_recipient
    MailRecipient.new(
      name: hearing.judge&.full_name,
      email: virtual_hearing.judge_email,
      title: MailRecipient::RECIPIENT_TITLES[:judge]
    )
  end

  def representative_recipient
    MailRecipient.new(
      name: appeal.representative_name,
      email: virtual_hearing.representative_email,
      title: MailRecipient::RECIPIENT_TITLES[:representative]
    )
  end

  def validate_veteran_deceased
    # Fail-safe check to ensure the recipient of an email is never a deceased veteran.
    # Handle these on a case-by-case basis.
    fail RecipientIsDeceasedVeteran if veteran.deceased?
  end

  def validate_veteran_name
    veteran.update_cached_attributes! if veteran.first_name.nil? || veteran.last_name.nil?

    fail "Veteran name is not populated" unless veteran.first_name.present? && veteran.last_name.present?
  end

  def appellant_recipient
    recipient_name = if appeal.appellant_is_not_veteran
                       appeal.appellant_first_name
                     elsif veteran.present?
                       validate_veteran_deceased
                       validate_veteran_name

                       veteran.first_name
                     else
                       "Appellant"
                     end

    MailRecipient.new(
      name: recipient_name,
      email: virtual_hearing.appellant_email,
      title: MailRecipient::RECIPIENT_TITLES[:appellant]
    )
  end

  def should_judge_receive_email?
    !virtual_hearing.judge_email.nil? && !virtual_hearing.judge_email_sent && type.to_s != "cancellation"
  end
end
