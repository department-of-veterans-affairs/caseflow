# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  # Purpose: POST request to VA Notify API to update status for a Notification entry.
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding Notification status
  def notifications_update
    send_sqs_message
    render json: {
      message: "#{params['notification_type']} Notification successfully updated: ID #{params['id']}"
    }
  rescue StandardError => error
    log_error(error, params["id"], params["notification_type"])
    render json: { error: error.message }, status: :bad_request
  end

  private

  def va_notify_params
    params.permit(:id, :notification_type, :status, :status_reason, :to)
  end

  def build_message_body
    id_param, notification_type_param, status_param = va_notify_params.require([:id, :notification_type, :status])

    {
      external_id: id_param,
      notification_type: notification_type_param,
      recipient: va_notify_params[:to],
      status: status_param,
      status_reason: va_notify_params[:status_reason]
    }
  rescue StandardError => error
    raise error
  end

  def build_sqs_message
    message_body = build_message_body.to_json

    {
      queue_url: SqsService.find_queue_url_by_name(name: "receive_notifications"),
      message_body: message_body,
      message_deduplication_id: Digest::SHA256.hexdigest(message_body),
      message_group_id: Constants.VA_NOTIFY_CONSTANTS.message_group_id
    }
  rescue StandardError => error
    raise error
  end

  def send_sqs_message
    sqs = SqsService.sqs_client
    sqs.send_message(build_sqs_message)
  end

  def log_error(error, external_id, notification_type)
    Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}\n \
                       external_id: #{external_id}\n \
                       notification_type: #{notification_type}")
    Raven.capture_exception(error)
  end
end
