# frozen_string_literal: true

class EmailUpdateJob < CaseflowJob
  queue_with_priority :high_priority

  def perform
    RequestStore[:current_user] = User.system_user

    redis.scan_each(match: "email_update:*") do |key, val|
      rows_updated = Notification.where(
        email_notification_external_id: key[/\d+/]
      ).update_all(email_notification_status: val)

      log_error(val) if rows_updated.zero?
    end
  rescue StandardError => error
    log_error(error)
  end
end
