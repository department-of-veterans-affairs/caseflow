# frozen_string_literal: true

module HasHearingEmailRecipientsConcern
  extend ActiveSupport::Concern

  def appellant_recipient
    recipient = AppellantHearingEmailRecipient.find_by(hearing: self)

    if recipient.blank? && virtual_hearing.present?
      appellant_email = virtual_hearing[:appellant_email]
      recipient = create_or_update_recipients(
        type: AppellantHearingEmailRecipient,
        email_address: appellant_email,
        timezone: virtual_hearing[:appellant_tz],
        email_sent: virtual_hearing[:appellant_email_sent]
      )

      update_email_events(recipient, recipient.roles)
    end

    recipient
  end

  def representative_recipient
    recipient = RepresentativeHearingEmailRecipient.find_by(hearing: self)

    if recipient.blank? && virtual_hearing.present?
      rep_email = virtual_hearing[:representative_email]

      if rep_email.present?
        recipient = create_or_update_recipients(
          type: RepresentativeHearingEmailRecipient,
          email_address: rep_email,
          email_sent: virtual_hearing[:representative_email_sent],
          timezone: virtual_hearing[:representative_tz]
        )

        update_email_events(recipient, recipient.roles)
      end
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

  ## BEGIN Email Related accessors
  def veteran_email_address
    appellant_email_address
  end

  def appellant_email_address
    appellant_recipient.present? ? appellant_recipient.email_address : appeal.appellant_email_address
  end

  def appellant_tz
    appellant_recipient.present? ? appellant_recipient.timezone : appeal.appellant_tz
  end

  def representative_email_address
    representative_recipient.present? ? representative_recipient.email_address : appeal&.representative_email_address
  end

  def representative_tz
    representative_recipient.present? ? representative_recipient.timezone : appeal&.representative_tz
  end


  private

  def update_email_events(recipient, roles)
    events = email_events.where(recipient_role: roles)

    events.each { |event| event.update!(email_recipient: recipient) }
  end
end
