# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  # Purpose: POST request to VA Notify API to update status for a Notification entry
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding Notification status
  def notifications_update
    send "#{required_params[:notification_type]}_update"
  end

  private

  # Purpose: Finds and updates notification if type is email
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding email Notification status
  def email_update
    redis.set("email_update:#{required_params[:id]}:#{required_params[:status]}", 0)

    render json: { message: "Email notification successfully updated: ID #{required_params[:id]}" }
  end

  # Purpose: Finds and updates notification if type is SMS
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding SMS Notification status
  def sms_update
    redis.set("sms_update:#{required_params[:id]}:#{required_params[:status]}", 0)

    render json: { message: "SMS notification successfully updated: ID #{required_params[:id]}" }
  end

  def required_params
    id_param, notification_type_param, status_param = params.require([:id, :notification_type, :status])

    { id: id_param, notification_type: notification_type_param, status: status_param }
  end

  def redis
    @redis ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end
end
