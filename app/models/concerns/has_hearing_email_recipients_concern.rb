# frozen_string_literal: true

# When virtual hearings were first added as an option (2019/2020) email related information was stored directly
# on the VirtualHearing. Emails were not being sent for any non-virtual hearings. In 2021 HearingEmailRecipient
# and related code as added to allow sending emails for all hearings (not just virtual ones).
#
# Instead of doing a big migration to move all email related information from VirtualHearing objects to new
# HearingEmailRecipient objects, the code in this file was set up to do an in place migration.
#
# The idea is that
# - As new hearings (of any type) are created, HearingEmailRecipient objects are added (the new way).
# - If a hearing is accessed where the email information is stored on the VirtualHearing (the old way).
#   - This concern creates the appropriate HearingEmailRecipient objects (the new way).
# That's why there are so many checks like virtual_hearing[:appellant_email] in this file. It's looking to
# see if this record might have data stored on VirtualHearing and if it does it's migrating it to the new
# HearingEmailRecipient.
#
# This fallback would ideally only be in this file, but it is also in:
# - HearingTimeService::poa_time and HearingTimeService::appellant_time

# rubocop:disable Metrics/ModuleLength
module HasHearingEmailRecipientsConcern
  extend ActiveSupport::Concern

  def appellant_recipient
    # Is there an existing appellant recipient for this hearing? Return it if yes
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")

    # There's no recipient, but there is an email address on the VirtualHearing, create a HearingEmailRecipient
    if recipient.blank? && appellant_email_address.present?
      recipient = create_or_update_recipients(
        type: AppellantHearingEmailRecipient,
        email_address: appellant_email_address,
        timezone: appellant_tz,
        email_sent: virtual_hearing.present? ? virtual_hearing[:appellant_email_sent] : true
      )

      # Change the email events to point to the new HearingEmailRecipient
      update_email_events(recipient, recipient.roles)
    end

    recipient
  end

  def representative_recipient
    # Is there an existing representative recipient for this hearing? Return it if yes
    recipient = email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")

    # There's no recipient, but there is an email address on the VirtualHearing, create a HearingEmailRecipient
    if recipient.blank? && representative_email_address.present?
      recipient = create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: representative_email_address,
        timezone: representative_tz,
        email_sent: virtual_hearing.present? ? virtual_hearing[:representative_email_sent] : true
      )

      # Change the email events to point to the new HearingEmailRecipient
      update_email_events(recipient, recipient.roles)
    end

    recipient
  end

  def judge_recipient
    # Is there an existing judge recipient for this hearing? Return it if yes
    recipient = JudgeHearingEmailRecipient.find_by(hearing: self)

    # There's no recipient, but there is an email address on the VirtualHearing, create a HearingEmailRecipient
    if recipient.blank? && virtual_hearing.present?
      judge_email = virtual_hearing[:judge_email]

      if judge_email.present?
        recipient = create_or_update_recipients(
          type: JudgeHearingEmailRecipient,
          email_address: judge_email,
          email_sent: virtual_hearing[:judge_email_sent]
        )

        # Change the email events to point to the new HearingEmailRecipient
        update_email_events(recipient, recipient.roles)
      end
    end

    recipient
  end

  # Check that the appellant email has been sent and that the representative, and judge either:
  # - Have email addresses and the emails have been sent
  # - Have no email addresses so no emails have been sent
  def all_emails_sent?
    appellant_recipient&.email_sent &&
      (judge_recipient&.email_address.nil? || judge_recipient&.email_sent) &&
      (representative_recipient&.email_address.nil? || representative_recipient&.email_sent)
  end

  # Same idea as all_emails_sent
  def cancellation_emails_sent?
    appellant_recipient&.email_sent &&
      (representative_recipient&.email_address.nil? || representative_recipient&.email_sent)
  end

  # Each Hearing/LegacyHearing can only have one HearingEmailRecipient of each type, so either
  # update or create it when the email address or timezone changes.
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

  # Alias
  def veteran_email_address
    appellant_email_address
  end

  # Get the appellant email address from the HearingEmailRecipient or the VirtualHearing
  def appellant_email_address
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")

    if recipient.blank?
      virtual_hearing.present? ? virtual_hearing[:appellant_email] : appeal&.appellant_email_address
    else
      recipient&.email_address
    end
  end

  # Get the appellant timezone from the HearingEmailRecipient or the VirtualHearing
  def appellant_tz
    recipient = email_recipients.find_by(type: "AppellantHearingEmailRecipient")

    if recipient.blank?
      virtual_hearing.present? ? virtual_hearing[:appellant_tz] : appeal&.appellant_tz
    else
      recipient&.timezone || appeal&.appellant_tz
    end
  end

  # Get the representative from the HearingEmailRecipient or the VirtualHearing
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

  # Get the representative timezone from the HearingEmailRecipient or the VirtualHearing
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

  # Change email events for a role to point to the specified HearingEmailRecipient
  def update_email_events(recipient, roles)
    events = email_events.where(recipient_role: roles)

    events.each { |event| event.update!(email_recipient: recipient) }
  end
end
# rubocop:enable Metrics/ModuleLength
