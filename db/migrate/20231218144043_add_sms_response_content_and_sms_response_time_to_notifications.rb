class AddSmsResponseContentAndSmsResponseTimeToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :sms_response_content, :string, comment: "Message body of the sms notification response."
    add_column :notifications, :sms_response_time, :datetime, comment: "Date and Time of the sms notification response."
  end
end
