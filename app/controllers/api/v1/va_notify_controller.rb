# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  # Purpose: POST request to VA Notify API to update status for a Notification entry
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding Notification status
  def notifications_update
    send "#{required_params[:notification_type]}_update"
    # if required_params[:notification_type] == "email"
    #   email_update
    # elsif required_params[:notification_type] == "sms"
    #   sms_update
    # end
  rescue NoMethodError => error
    log_error(error.message)
  end

  private

  # Purpose: Log error in Rails logger and gives 500 error
  #
  # Params:  Notification type string, either "email" or "SMS"
  #
  # Response: json error message with uuid and 500 error
  def log_error(notification_type)
    uuid = SecureRandom.uuid
    error_msg = "An #{notification_type} notification with id #{required_params[:id]} could not be found. " \
                "Error ID: #{uuid}"
    Rails.logger.error(error_msg)
    render json: { message: error_msg }, status: :internal_server_error
  end

  # Purpose: Finds and updates notification if type is email
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding email Notification status
  def email_update
    # find notification through external id
    # rows_updated = Notification.where(
    #   email_notification_external_id: required_params[:id]
    # ).update_all(email_notification_status: required_params[:status])

    # # log external id if notification doesn't exist
    # return log_error(required_params[:notification_type]) if rows_updated.zero?

    # store for later processing
    redis.set("email_update_#{required_params[:id]}", required_params[:status])

    render json: { message: "Email notification successfully updated: ID " + required_params[:id] }
  end

  # Purpose: Finds and updates notification if type is SMS
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding SMS Notification status
  def sms_update
    # find notification through external id
    rows_updated = Notification.where(
      sms_notification_external_id: required_params[:id]
    ).update_all(sms_notification_status: required_params[:status])

    # log external id if notification doesn't exist
    return log_error(required_params[:notification_type]) if rows_updated.zero?

    render json: { message: "SMS notification successfully updated: ID " + required_params[:id] }
  end

  def required_params
    id_param, notification_type_param, status_param = params.require([:id, :notification_type, :status])

    { id: id_param, notification_type: notification_type_param, status: status_param }
  end

  def redis
    @redis ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end
end
