# frozen_string_literal: true

# Service for resending confirmation emails

class VirtualHearings::ResendVirtualHearingEmailsService
  class << self
    def call(start_date:, end_date:)
      confirmation_hearing_email_events.each do |sent_email|
        message = get_gov_delivery_message_body(sent_email)
        if is_bad_email?(message[:body]) && hearing_has_non_confirmation_emails?(sent_email.hearing)
          reset_email_sent_on_email_recipients(sent_email.hearing)
          Hearings::SendEmail.new(
            virtual_hearing: se.hearing.virtual_hearing, 
            type: :confirmation,
            hearing: se.hearing
          ).call
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

    def is_bad_email?(email_body)
      email_body.include?("care.va.gov")
    end

    def hearing_has_non_confirmation_emails?(hearing)
      hearing.email_events.any? {|email_event| email_event.email_type != "confirmation" }
    end

    def reset_email_sent_on_email_recipients(hearing)
      hearing.email_recipients.update_all(email_sent: false)
    end
  end
end