# frozen_string_literal: true

class AddNotificationIdAndStatusIndexes < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_index :notifications,
              :email_notification_external_id,
              algorithm: :concurrently

    add_index :notifications,
              :email_notification_status,
              algorithm: :concurrently

    add_index :notifications,
              :sms_notification_external_id,
              algorithm: :concurrently

    add_index :notifications,
              :sms_notification_status,
              algorithm: :concurrently
  end
end
