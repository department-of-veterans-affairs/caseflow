# frozen_string_literal: true

# Service for resending confirmation emails

class VirtualHearings::ResendVirtualHearingEmailsService
  class << self
    # :nocov:
    def call(start_date:, end_date:, perform_resend: false)
      confirmation_email_events_in_date_range = confirmation_hearing_email_events(start_date, end_date)
      email_events_to_resend = confirmation_email_events_in_date_range.select { |cee| should_resend_email?(cee) }
      if perform_resend
        email_events_to_resend.each { |ee| reset_sent_status_and_send(ee) }
      else
        email_events_to_resend
      end
    end

    # This method is specific to a problem where :confirmation emails were going out with the wrong link in a
    # certain time period. This allows tracking/retrieval of all the resent emails.
    def find_resent_confirmation_email_events
      start_date = "16/Aug/2021 00:00:00 +0500" # Day before confirmation email problem potentially started
      end_date = "17/Nov/2021 00:00:00 +0500" # Day after confirmation email  problem was stopped
      events_in_date_range = SentHearingEmailEvent.where("sent_at > ?", start_date).where("sent_at < ?", end_date)

      confirmations_with_system_user = events_in_date_range.where(email_type: :confirmation)
        .where(sent_by: User.system_user)

      resent_email_events = confirmations_with_system_user.inject([]) do |events, confirmation|
        events + confirmation.hearing.email_events.where("sent_at > ?", end_date).where(email_type: :confirmation)
      end

      resent_email_events.sort_by { |event| event[:hearing_id] }.uniq
    end

    def reset_sent_status_and_send(sent_email)
      begin
        reset_email_sent_on_email_recipients(sent_email.hearing)
        Hearings::SendEmail.new(
          custom_subject: custom_email_subject(sent_email.hearing),
          virtual_hearing: sent_email.hearing.virtual_hearing,
          type: :confirmation,
          hearing: sent_email.hearing
        ).call
        sent_email.update(sent_by: User.system_user)
      rescue StandardError, Hearings::SendEmail::RecipientIsDeceasedVeteran => error
        Raven.capture_exception(error, extra: { application: "hearings" })
      end
    end

    def confirmation_hearing_email_events(start_date, end_date)
      SentHearingEmailEvent.where(sent_at: [Time.zone.parse(start_date)..Time.zone.parse(end_date)])
        .where(email_type: "confirmation").all.order(sent_at: :desc)
    end

    def get_gov_delivery_message_body(sent_email)
      ExternalApi::GovDeliveryService.get_message_subject_and_body_from_event(email_event: sent_email)
    end

    def should_resend_email?(sent_email)
      begin
        return false unless sent_email.hearing.virtual?

        return false if sent_email.hearing.scheduled_for.past?

        return false if hearing_has_non_confirmation_emails?(sent_email.hearing)

        return false if sent_email.sent_hearing_admin_email_event.present?

        # Reminder emails can also have User.system user as the sender, this works because we're only interested in
        # confirmation emails for now.
        return false if sent_email.sent_by == User.system_user

        message = get_gov_delivery_message_body(sent_email)
        bad_email?(message[:body])
      rescue StandardError, Caseflow::Error::VacolsRecordNotFound => error
        Raven.capture_exception(error, extra: { application: "hearings" })
      end
    end

    def bad_email?(email_body)
      email_body.include?("care.va.gov")
    end

    def hearing_has_non_confirmation_emails?(hearing)
      hearing.email_events.any? { |email_event| email_event.email_type != "confirmation" }
    end

    def reset_email_sent_on_email_recipients(hearing)
      hearing.email_recipients.update_all(email_sent: false)
    end

    def custom_email_subject(hearing)
      "Updated confirmation (please disregard previous email): " \
      "#{hearing.appeal.appellant_or_veteran_name}'s Board hearing is " \
      "#{hearing.scheduled_for.to_formatted_s(:short_date)} -- Do Not Reply"
    end
  end
  # :nocov:
end
