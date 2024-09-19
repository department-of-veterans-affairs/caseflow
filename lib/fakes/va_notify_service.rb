# frozen_string_literal: true

class Fakes::VANotifyService < ExternalApi::VANotifyService
  VA_NOTIFY_ENDPOINT = "/api/v1/va_notify_update"

  class << self
    # rubocop:disable  Metrics/ParameterLists
    def send_email_notifications(
      participant_id:,
      notification_id:,
      email_template_id:,
      first_name:,
      docket_number:,
      status: ""
    )

      external_id = SecureRandom.uuid

      unless Rails.deploy_env == :test
        request = HTTPI::Request.new
        request.url = "#{ENV['CASEFLOW_BASE_URL']}#{VA_NOTIFY_ENDPOINT}"\
          "?id=#{external_id}&status=delivered&to=test@example.com&notification_type=email"
        request.headers["Content-Type"] = "application/json"
        request.headers["Authorization"] = "Bearer test"
        request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

        HTTPI.post(request)
      end

      fake_notification_response(email_template_id, status, external_id)
    end

    def send_sms_notifications(
      participant_id:,
      notification_id:,
      sms_template_id:,
      first_name:,
      docket_number:,
      status: ""
    )

      external_id = SecureRandom.uuid

      unless Rails.deploy_env == :test
        request = HTTPI::Request.new
        request.url = "#{ENV['CASEFLOW_BASE_URL']}#{VA_NOTIFY_ENDPOINT}"\
          "?id=#{external_id}&status=delivered&to=+15555555555&notification_type=sms"
        request.headers["Content-Type"] = "application/json"
        request.headers["Authorization"] = "Bearer test"
        request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

        HTTPI.post(request)
      end

      if participant_id.length.nil?
        return bad_participant_id_response
      end

      fake_notification_response(sms_template_id, status, external_id)
    end
    # rubocop:enable  Metrics/ParameterLists

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

    def fake_notification_response(template_id, status, external_id)
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": external_id,
          "reference": "string",
          "uri": "string",
          "template": {
            "id" => template_id,
            "version" => 0,
            "uri" => "string"
          },
          "scheduled_for": "string",
          "content": {
            "body" => "Template: #{template_id} - Status: #{status}",
            "subject" => "Test Subject"
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
