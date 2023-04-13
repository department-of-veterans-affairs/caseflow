# frozen_string_literal: true

class Api::V1::VaNotifyController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def notifications_update
  # get params here
    notif = Notification.find(params[:id])
    if notif
      if notif[email_notification_external_id] == params[:email_notification_external_id]
        notif[email_notification_status] = params[:email_notification_status]
      elsif notif[sms_notification_external_id] == params[:sms_notification_external_id]
        notif[sms_notification_status] = params[:sms_notification_status]
      end
    else
      notif = Notification.new(
        appeals_id: appeals_id,
        appeals_type: appeals_type,
        event_type: event_type,
        notification_type: notification_type,
        participant_id: participant_id,
        notified_at: Time.zone.now,
        event_date: Time.zone.today
      )
    end
    notif.save
  end
end
