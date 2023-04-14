# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def notifications_update
    notif = Notification.find(params["id"])
    if notif
      if notif[:email_notification_external_id] == params["email_notification_external_id"]
        notif[:email_notification_status] = params["email_notification_status"]
      elsif notif[:sms_notification_external_id] == params["sms_notification_external_id"]
        notif[:sms_notification_status] = params["sms_notification_status"]
      end
    else
      notif = Notification.new(
        appeals_id: params["appeals_id"],
        appeals_type: params["appeals_type"],
        created_at: params["created_at"],
        email_enabled: params["email_enabled"],
        email_notification_content: params["email_notification_content"],
        email_notification_external_id: params["email_notification_external_id"],
        email_notification_status: params["email_notification_status"],
        event_date: params["event_date"],
        event_type: params["event_type"],
        notification_content: params["notification_content"],
        notification_type: params["notification_type"],
        notified_at: params["notified_at"],
        participant_id: params["participant_id"],
        recipient_email: params["recipient_email"],
        recipient_phone_number: params["recipient_phone_number"],
        sms_notification_content: params["sms_notification_content"],
        sms_notification_external_id: params["sms_notification_external_id"],
        sms_notification_status: params["sms_notification_status"],
        updated_at: params["updated_at"]
      )
    end
    notif.save
  end
end
