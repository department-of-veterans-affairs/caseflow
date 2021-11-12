# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module HasHearingEmailRecipientsConcern
  extend ActiveSupport::Concern

  def appellant_recipient
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")

    if recipient.blank? && appellant_email_address.present?
      recipient = create_or_update_recipients(
        type: AppellantHearingEmailRecipient,
        email_address: appellant_email_address,
        timezone: appellant_tz,
        email_sent: virtual_hearing.present? ? virtual_hearing[:appellant_email_sent] : true
      )

      update_email_events(recipient, recipient.roles)
    end

    recipient
  end

  def representative_recipient
    recipient = email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")

    if recipient.blank? && representative_email_address.present?
      recipient = create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: representative_email_address,
        timezone: representative_tz,
        email_sent: virtual_hearing.present? ? virtual_hearing[:representative_email_sent] : true
      )

      update_email_events(recipient, recipient.roles)
    end

    recipient
  end

  def judge_recipient
    recipient = JudgeHearingEmailRecipient.find_by(hearing: self)

    if recipient.blank? && virtual_hearing.present?
      judge_email = virtual_hearing[:judge_email]

      if judge_email.present?
        recipient = create_or_update_recipients(
          type: JudgeHearingEmailRecipient,
          email_address: judge_email,
          email_sent: virtual_hearing[:judge_email_sent]
        )

        update_email_events(recipient, recipient.roles)
      end
    end

    recipient
  end

  def all_emails_sent?
    appellant_recipient&.email_sent &&
      (judge_recipient&.email_address.nil? || judge_recipient&.email_sent) &&
      (representative_recipient&.email_address.nil? || representative_recipient&.email_sent)
  end

  def cancellation_emails_sent?
    appellant_recipient&.email_sent &&
      (representative_recipient&.email_address.nil? || representative_recipient&.email_sent)
  end

  def create_or_update_recipients(type:, email_address:, timezone: nil, email_sent: false)
    recipient = type.find_by(hearing: self)

    if recipient.blank?
      type.create!(
        hearing: self,
        email_address: email_address,
        timezone: timezone,
        email_sent: email_sent
      )
    else
      recipient.update!(
        email_address: email_address,
        timezone: timezone,
        email_sent: email_sent
      )
    end
  end

  def veteran_email_address
    appellant_email_address
  end

  def appellant_email_address
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")

    if recipient.blank?
      virtual_hearing.present? ? virtual_hearing[:appellant_email] : appeal&.appellant_email_address
    else
      recipient&.email_address
    end
  end

  def appellant_tz
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")

    if recipient.blank?
      virtual_hearing.present? ? virtual_hearing[:appellant_tz] : appeal&.appellant_tz
    else
      recipient&.timezone || appeal&.appellant_tz
    end
  end

  def representative_email_address
    recipient = email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")

    if recipient.blank?
      if virtual_hearing.present?
        virtual_hearing[:representative_email].presence
      else
        representative_tz.present? ? appeal&.representative_email_address : nil
      end
    else
      recipient&.email_address
    end
  end

  def representative_tz
    recipient = email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")

    if recipient.blank?
      begin
        virtual_hearing.present? ? virtual_hearing[:representative_tz].presence : appeal&.representative_tz
      rescue Module::DelegationError
        nil
      end
    else
      recipient&.timezone
    end
  end

  private

  def update_email_events(recipient, roles)
    events = email_events.where(recipient_role: roles)

    events.each { |event| event.update!(email_recipient: recipient) }
  end
end
# rubocop:enable Metrics/ModuleLength
