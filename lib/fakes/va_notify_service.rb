# frozen_string_literal: true

class Fakes::VANotifyService < ExternalApi::VANotifyService
  class << self
    def send_email_notifications(participant_id, notification_id, email_template_id, first_name, docket_number, status = "")
      fake_notification_response(email_template_id)
    end

    def send_sms_notifications(participant_id, notification_id, sms_template_id, first_name, docket_number, status = "")
      if participant_id.length.nil?
        return bad_participant_id_response
      end

      fake_notification_response(sms_template_id)
    end

    def get_status(notification_id)
      fake_status_response(notification_id)
    end

    private

    def bad_participant_id_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "participant id is not valid"
        )
      )
    end

    def bad_email_address_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "email is not valid"
        )
      )
    end

    def bad_email_template_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "email template id not valid"
        )
      )
    end

    def bad_phone_number_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "phone number not valid"
        )
      )
    end

    def bad_sms_template_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "sms template id not valid"
        )
      )
    end

    def bad_notification_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "notification id not valid"
        )
      )
    end

    def fake_notification_response(email_template_id)
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": SecureRandom.uuid,
          "reference": "string",
          "uri": "string",
          "template": {
            "id" => email_template_id,
            "version" => 0,
            "uri" => "string"
          },
          "scheduled_for": "string",
          "content": {
            "body" => "string",
            "subject" => "string"
          }
        )
      )
    end

    # rubocop:disable Metrics/MethodLength
    def fake_status_response(notification_id)
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
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
              "id_type" => "VAPROFILEID",
              "id_value" => "string"
            }
          ],
          "reference": "string",
          "scheduled_for": "2022-08-08T16:20:50.090Z",
          "sent_at": "2022-08-08T16:20:50.090Z",
          "sent_by": "string",
          "status": "created",
          "subject": "string",
          "template": {
            "id" => "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "uri" => "string",
            "version" => 0
          },
          "type" => "email"
        )
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
