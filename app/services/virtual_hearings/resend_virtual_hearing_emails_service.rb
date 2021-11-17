# frozen_string_literal: true

# Service for resending confirmation emails

class VirtualHearings::ResendVirtualHearingEmailsService
  class << self
    def call(start_date:, end_date:)
      confirmation_hearing_email_events(start_date, end_date).each do |sent_email|
        if should_resend_email?(sent_email)
          reset_email_sent_on_email_recipients(sent_email.hearing)
          Hearings::SendEmail.new(
            custom_subject: custom_email_subject(sent_email.hearing),
            virtual_hearing: sent_email.hearing.virtual_hearing,
            type: :confirmation,
            hearing: sent_email.hearing
          ).call
          SentHearingAdminEmailEvent.create(sent_hearing_email_event: sent_email)
        end
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
      return false unless sent_email.hearing.virtual?

      return false if sent_email.hearing.scheduled_for.past?

      return false if hearing_has_non_confirmation_emails?(sent_email.hearing)

      return false if sent_email.sent_hearing_admin_email_event.present?

      message = get_gov_delivery_message_body(sent_email)
      bad_email?(message[:body])
    end

    def bad_email?(email_body)
      email_body.include?("care.va.gov")
    end

    def hearing_has_non_confirmation_emails?(hearing)
      hearing.email_events.any? {|email_event| email_event.email_type != "confirmation" }
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
end
