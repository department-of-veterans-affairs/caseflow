class AddSmSandEmailStatusToNotifications < ActiveRecord::Migration[6.0]
  def change
    add_column :notifications, :sms_status_reason, :string, comment: "Context around why this VA Notify notification is in the sms status"
    add_column :notifications, :email_status_reason, :string, comment: "Context around why this VA Notify notification is in the email status"
  end
end
