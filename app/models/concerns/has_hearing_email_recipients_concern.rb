# frozen_string_literal: true

module HasHearingEmailRecipientsConcern
  extend ActiveSupport::Concern

  def appellant_recipient
    # If there's an existing AppellantHearingEmailRecipient return that
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")
    return recipient if recipient.present?

    # If there is no AppellantHearingEmailRecipient, its possible that the email address for
    # this recipient exist only on the virtual hearing and needs to be migrated
    if appellant_email_address.present?
      # Create a new recipient from the virtual hearing, this is a migration from when we stored
      # email recipients only for virtual hearings
      recipient = create_or_update_recipients(
        type: AppellantHearingEmailRecipient,
        email_address: appellant_email_address, timezone: appellant_tz,
        email_sent: virtual_hearing.present? ? virtual_hearing[:appellant_email_sent] : true
      )

      # Update the email events that were pointing at the virtual hearing to use the newly
      # created AppellantHearingEmailRecipient
      update_email_events(recipient, recipient.roles)
    end
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
    return recipient&.email_address if recipient.present?

    # If no existing recipient, fall back to the virtual hearing
    # If we don't have an existing recipient, fall back to the virtual hearing
    virtual_hearing.present? ? virtual_hearing[:appellant_email] : appeal&.appellant_email_address
  end

  def appellant_tz
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")
    return recipient&.timezone || appeal&.appellant_tz if recipient.present?

    # If no existing recipient, fall back to the virtual hearing
    virtual_hearing.present? ? virtual_hearing[:appellant_tz] : appeal&.appellant_tz
  end

  def representative_email_address
    recipient = email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")
    return recipient&.email_address if recipient.present?

    return virtual_hearing[:representative_email].presence if virtual_hearing.present?

    # If no existing recipient, fall back to the virtual hearing
    representative_tz.present? ? appeal&.representative_email_address : nil
  end

  def representative_tz
    recipient = email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")
    return recipient&.timezone if recipient.present?

    begin
      # If no existing recipient, fall back to the virtual hearing
      virtual_hearing.present? ? virtual_hearing[:representative_tz].presence : appeal&.representative_tz
    rescue Module::DelegationError
      nil
    end
  end

  private

  def update_email_events(recipient, roles)
    events = email_events.where(recipient_role: roles)

    events.each { |event| event.update!(email_recipient: recipient) }
  end
end
