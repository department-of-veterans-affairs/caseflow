# frozen_string_literal: true

class EmailStatusUpdateJob < CaseflowJob
  queue_with_priority :high_priority

  UUID_REGEX = /[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

  def perform
    RequestStore[:current_user] = User.system_user

    redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

    # prefer scan so we only load a single record into memory,
    # dumping the whole list could cause performance issues when job runs
    redis.scan_each(match: "email_update:*") do |key, val|
      rows_updated = Notification.where(
        email_notification_external_id: key[UUID_REGEX]
      ).update_all(email_notification_status: val)

      fail StandardError if rows_updated.zero?

      # cleanup keys
      redis.del key
    end
  rescue StandardError => error
    log_error(error)
  end
end
