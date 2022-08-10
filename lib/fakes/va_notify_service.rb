# frozen_string_literal: true

class Fakes::VANotifyService < ExternalApi::VANotifyService
  class << self
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def send_notifications(email_address, email_template_id, phone_number, sms_template_id, status = nil)
      if !email_address.include?("@")
        return bad_email_address_response
      end

      if email_template_id.length != 36
        return bad_email_template_response
      end

      if phone_number && ((phone_number.length != 12) || (phone_number !~ /^\+/))
        return bad_phone_number_response
      end

      if sms_template_id && sms_template_id.length != 36
        return bad_sms_template_response
      end

      fake_notification_response(email_template_id)
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    def get_status(notification_id)
      return bad_notification_response if notification_id.length != 36

      fake_status_response(notification_id)
    end

    private

    def bad_email_address_response
      [{
        "error": "BadRequestError",
        "message": "email is not valid"
      }]
    end

    def bad_email_template_response
      [{
        "error": "BadRequestError",
        "message": "email template id not valid"
      }]
    end

    def bad_phone_number_response
      [{
        "error": "BadRequestError",
        "message": "phone number not valid"
      }]
    end

    def bad_sms_template_response
      [{
        "error": "BadRequestError",
        "message": "sms template id not valid"
      }]
    end

    def bad_notification_response
      [{
        "error": "BadRequestError",
        "message": "notification id not valid"
      }]
    end

    def fake_notification_response(email_template_id)
      response = {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "reference": "string",
        "uri": "string",
        "template": {
          "id": email_template_id,
          "version": 0,
          "uri": "string"
        },
        "scheduled_for": "string",
        "content": {
          "body": "string",
          "subject": "string"
        }
      }
      response
    end

    # rubocop:disable Metrics/MethodLength
    def fake_status_response(notification_id)
      {
        "id": notification_id,
        "body": "string",
        "completed_at": "2022-08-08T16:20:50.090Z",
        "created_at": "2022-08-08T16:20:50.090Z",
        "created_by_name": "string",
        "email_address": "user@example.com",
        "line_1": "string",
        "line_2": "string",
        "line_3": "string",
        "line_4": "string",
        "line_5": "string",
        "line_6": "string",
        "phone_number": "+16502532222",
        "postage": "string",
        "postcode": "string",
        "recipient_identifiers": [
          {
            "id_type": "VAPROFILEID",
            "id_value": "string"
          }
        ],
        "reference": "string",
        "scheduled_for": "2022-08-08T16:20:50.090Z",
        "sent_at": "2022-08-08T16:20:50.090Z",
        "sent_by": "string",
        "status": "created",
        "subject": "string",
        "template": {
          "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "uri": "string",
          "version": 0
        },
        "type": "email"
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
end
