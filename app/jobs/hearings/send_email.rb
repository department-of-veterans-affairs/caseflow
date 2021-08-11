# frozen_string_literal: true

class Hearings::SendEmail
  class RecipientIsDeceasedVeteran < StandardError; end

  attr_reader :hearing, :virtual_hearing, :type

  def initialize(virtual_hearing:, type:, hearing: nil)
    @hearing = virtual_hearing.hearing || hearing
    @type = type.to_s
  end

  def call
    # Assumption: Reminders and confirmation/cancellation/change emails are sent
    # separately, so this will return early if any reminder emails are sent. If
    # reminder emails are being sent, we are assuming the other emails have all
    # already been sent too.
    return if send_reminder

    # Unless this is a reminder, still require a virtual hearing for all emails
    # checking 'hearing.virtual?' doesnt work because some emails are 'cancellation's
    # which means the virtual hearing has been cancelled and hearing.virtual? == false
    return if !hearing.virtual_hearing

    if !hearing.appellant_recipient.email_sent
      appellant_recipient.update!(email_sent: send_email(appellant_recipient_info))
    end

    if should_judge_receive_email?
      judge_recipient.update!(email_sent: send_email(judge_recipient_info))
    end

    if hearing.representative_recipient.email_address.present? && !hearing.representative_recipient.email_sent
      representative_recipient.update!(email_sent: send_email(representative_recipient_info))
    end
  end

  private

  delegate :appeal, to: :hearing
  delegate :appellant_recipient, :representative_recipient, :judge_recipient, to: :hearing
  delegate :veteran, to: :appeal

  def send_reminder
    if type == "appellant_reminder" && send_email(appellant_recipient_info)
      return true
    end

    if type == "representative_reminder" &&
       hearing.representative_recipient.email_address.present? &&
       send_email(representative_recipient_info)
      return true
    end

    false
  end

  def email_for_recipient(recipient_info)
    args = {
      email_recipient: recipient_info,
      virtual_hearing: hearing.virtual_hearing
    }

    case type
    when "confirmation"
      HearingMailer.confirmation(**args)
    when "cancellation"
      HearingMailer.cancellation(**args)
    when "updated_time_confirmation"
      HearingMailer.updated_time_confirmation(**args)
    when "appellant_reminder", "representative_reminder"
      args[:hearing] = hearing
      HearingMailer.reminder(**args)
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
        metric_name: "emails.submitted",
        attrs: {
          email_type: type
        }
      )

      Rails.logger.info(
        "[Hearing: #{hearing.id}] " \
        "GovDelivery returned (code: #{response.status}) (external url: #{response_external_url})"
      )

      response_external_url
    end
  end
  # :nocov:

  def send_email(recipient_info)
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
    email = email_for_recipient(recipient_info)

    return false if email.nil?

    Rails.logger.info("Sending email to #{recipient_info.inspect}...")
    msg = email.deliver_now!
  rescue StandardError, Savon::Error, BGS::ShareError => error
    # Savon::Error and BGS::ShareError are sometimes thrown when making requests to BGS endpoints
    Raven.capture_exception(error)

    Rails.logger.warn("Failed to send #{type} email to #{recipient_info.title}: #{error}")
    Rails.logger.warn(error.backtrace.join($INPUT_RECORD_SEPARATOR))

    false
  else
    Rails.logger.info("Sent #{type} email to #{recipient_info.title}!")

    create_sent_hearing_email_event(recipient_info, external_message_id(msg))

    true
  end

  # :nocov:
  def create_sent_hearing_email_event(recipient_info, external_id)
    # The "appellant" title is used in the email and is consistent whether or not the
    # veteran is or isn't the appellant, but the email event can be more specific.
    recipient_is_veteran = (
      recipient_info.title == HearingEmailRecipient::RECIPIENT_TITLES[:appellant] &&
      !hearing.appeal.appellant_is_not_veteran
    )

    ::SentHearingEmailEvent.create!(
      hearing: hearing,
      email_type: type.ends_with?("reminder") ? "reminder" : type,
      email_address: recipient_info.email,
      external_message_id: external_id,
      recipient_role: recipient_is_veteran ? "veteran" : recipient_info.title.downcase,
      sent_by: type.ends_with?("reminder") ? User.system_user : hearing.virtual_hearing.updated_by,
      email_recipient: recipient_info.hearing_email_recipient
    )
  rescue StandardError => error
    Raven.capture_exception(error)
  end
  # :nocov:

  def judge_recipient_info
    EmailRecipientInfo.new(
      name: hearing.judge&.full_name,
      title: HearingEmailRecipient::RECIPIENT_TITLES[:judge],
      hearing_email_recipient: judge_recipient
    )
  end

  def representative_recipient_info
    EmailRecipientInfo.new(
      name: hearing.appeal.representative_name,
      title: HearingEmailRecipient::RECIPIENT_TITLES[:representative],
      hearing_email_recipient: representative_recipient
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

  def appellant_recipient_info
    recipient_name = if hearing.appeal.appellant_is_not_veteran
                       hearing.appeal.appellant_name
                     elsif veteran.present?
                       validate_veteran_deceased
                       validate_veteran_name

                       hearing.appeal.veteran_full_name
                     else
                       "Appellant"
                     end

    EmailRecipientInfo.new(
      name: recipient_name,
      title: HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
      hearing_email_recipient: appellant_recipient
    )
  end

  def should_judge_receive_email?
    hearing.judge_recipient&.email_address.present? &&
      !hearing.judge_recipient&.email_sent &&
      %w[confirmation updated_time_confirmation].include?(type)
  end
end
