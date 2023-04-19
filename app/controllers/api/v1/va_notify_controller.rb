# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  def notifications_update
    if params["type"] == "email"
      notif = Notification.find_by(email_notification_external_id: params["id"])
      if notif
        notif.update!(email_notification_status: params["status"])
      else
        uuid = SecureRandom.uuid
        Rails.logger.error("An email notification with id " + params["id"] + " could not be found." + "Error ID: " + uuid)
        # Raven.capture_exception(error, extra: { error_uuid: uuid })
        fail
      end
    elsif params["type"] == "sms"
      notif = Notification.find_by(sms_notification_external_id: params["id"])
      if notif
        notif.update!(sms_notification_status: params["status"])
      else
        uuid = SecureRandom.uuid
        Rails.logger.error("An SMS notification with id " + params["id"] + " could not be found." + "Error ID: " + uuid)
        # Raven.capture_exception(error, extra: { error_uuid: uuid })
        fail
      end
    end
  end
end
