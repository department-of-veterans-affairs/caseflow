# frozen_string_literal: true

class ProcessNotificationStatusUpdatesJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    RequestStore[:current_user] = User.system_user

    redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

    # prefer scan so we only load a single record into memory,
    # dumping the whole list could cause performance issues when job runs
    redis.scan_each(match: "(sms|email)_update:*") do |key|
      begin
        notification_type, uuid, status = key.split(":")

        fail InvalidNotificationStatusFormat if [notification_type, uuid, status].any?(&:nil?)

        rows_updated = Notification.where(
          "#{notification_type}_notification_external_id" => uuid
        ).update_all("#{notification_type}_notification_status" => status)

        fail StandardError if rows_updated.zero?

        # cleanup keys
        redis.del key
      rescue StandardError => error
        log_error(error)
      end
    end
  end
end
