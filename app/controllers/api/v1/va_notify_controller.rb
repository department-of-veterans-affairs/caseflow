# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  # Purpose: POST request to VA Notify API to update status for a Notification entry
  #
  # Params: Params content can be found at https://vajira.max.gov/browse/APPEALS-21021
  #
  # Response: Update corresponding Notification status
  def notifications_update
    if params["type"] == "email"
      # find notification through external id
      notif = Notification.find_by(email_notification_external_id: params["id"])
      # update notification if it exists
      if notif
        notif.update!(email_notification_status: params["status"])
      # log external id if notification doesn't exist
      else
        uuid = SecureRandom.uuid
        error_msg = "An email notification with id " + params["id"] + " could not be found. " + "Error ID: " + uuid
        Rails.logger.error(error_msg)
        render json: { message: error_msg}, status: :internal_server_error
      end
    elsif params["type"] == "sms"
      # find notification through external id
      notif = Notification.find_by(sms_notification_external_id: params["id"])
      # update notification if it exists
      if notif
        notif.update!(sms_notification_status: params["status"])
      # log external id if notification doesn't exist
      else
        uuid = SecureRandom.uuid
        error_msg = "An SMS notification with id " + params["id"] + " could not be found.c" + "Error ID: " + uuid
        Rails.logger.error(error_msg)
        render json: { message: error_msg}, status: :internal_server_error
      end
    end
  end
end
