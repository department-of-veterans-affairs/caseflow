# frozen_string_literal: true

class ProcessNotificationStatusUpdatesJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    RequestStore[:current_user] = User.system_user

    redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

    # prefer scan so we only load a single record into memory,
    # dumping the whole list could cause performance issues when job runs
    redis.scan_each(match: "*_update:*") do |key|
      begin
        raw_notification_type, uuid, status = key.split(":")

        notification_type = extract_notification_type(raw_notification_type)

        fail InvalidNotificationStatusFormat if [notification_type, uuid, status].any?(&:nil?)

        rows_updated = Notification.where(
          "#{notification_type}_notification_external_id" => uuid
        ).update_all("#{notification_type}_notification_status" => status)

<<<<<<< HEAD
        fail StandardError, "No notification matches UUID #{uuid}" if rows_updated.zero?
=======
        fail StandardError, "No notification matches UUID" if rows_updated.zero?

        # cleanup keys
        redis.del key
>>>>>>> bf1c0cecb (Adding a few tests and refactor)
      rescue StandardError => error
        log_error(error)
      ensure
        # cleanup keys - do first so we don't reporcess any failed keys
        redis.del key
      end
    end
  end

  private

  def extract_notification_type(raw_notification_type)
    raw_notification_type.split("_").first
  end
end
