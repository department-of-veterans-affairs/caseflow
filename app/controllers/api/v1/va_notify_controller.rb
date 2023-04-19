# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  def notifications_update
    if params["type"] == "email"
      notif = Notification.find_by(email_notification_external_id: params["id"])
      if notif
        notif.update!(email_notification_status: params["status"])
      else
        uuid = SecureRandom.uuid
        error_msg = "An email notification with id " + params["id"] + " could not be found. " + "Error ID: " + uuid
        Rails.logger.error(error_msg)
        render json: { message: error_msg}, status: :internal_server_error
      end
    elsif params["type"] == "sms"
      notif = Notification.find_by(sms_notification_external_id: params["id"])
      if notif
        notif.update!(sms_notification_status: params["status"])
      else
        uuid = SecureRandom.uuid
        error_msg = "An SMS notification with id " + params["id"] + " could not be found.c" + "Error ID: " + uuid
        Rails.logger.error(error_msg)
        render json: { message: error_msg}, status: :internal_server_error
      end
    end
  end
end
