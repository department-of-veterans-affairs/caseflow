# frozen_string_literal: true

class EmailStatusUpdateJob < CaseflowJob
  queue_with_priority :high_priority

  def perform
    RequestStore[:current_user] = User.system_user

    redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

    redis.scan_each(match: "email_update:*") do |key, val|
      rows_updated = Notification.where(
        email_notification_external_id: key[/\d+/]
      ).update_all(email_notification_status: val)

      log_error(val) if rows_updated.zero?

      # cleanup keys
      redis.del key
    end
  rescue StandardError => error
    log_error(error)
  end
end
