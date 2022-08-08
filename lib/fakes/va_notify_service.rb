# frozen_string_literal: true

class Fakes::VANotifyService < ExternalApi::VANotifyService
  class << self
    def send_notifications(*)
      fake_email_response
    end

    def get_status(*)
      fake_status_response
    end

    def get_callback(*)
      fake_get_callback_response
    end

    def create_callback(*)
      fake_create_callback_reponse
    end

    def fake_email_response
      {
        "reference": "string",
        "template_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "personalisation": {
          "full_name": "John Smith",
          "claim_id": "123456"
        },
        "scheduled_for": "string",
        "billing_code": "string",
        "email_reply_to_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "email_address": "string"
      }
    end

    # rubocop:disable Metrics/MethodLength
    def fake_status_response
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
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

    def fake_get_callback_response
      {
        "data": [
          {
            "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "service_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "url": "string",
            "callback_type": "delivery_status",
            "created_at": "string",
            "updated_at": "string",
            "updated_by_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "notification_statuses": [
              "cancelled"
            ]
          }
        ]
      }
    end

    def fake_create_callback_reponse
      {
        "data": {
          "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "service_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "url": "string",
          "callback_type": "delivery_status",
          "created_at": "string",
          "updated_at": "string",
          "updated_by_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "notification_statuses": [
            "cancelled"
          ]
        }
      }
    end
  end
end
