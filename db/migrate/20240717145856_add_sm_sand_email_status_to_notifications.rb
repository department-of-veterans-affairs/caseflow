class AddSmSandEmailStatusToNotifications < ActiveRecord::Migration[6.0]
  def change
    add_column :notifications, :sms_status_reason, :string
    add_column :notifications, :email_status_reason, :string
  end
end
