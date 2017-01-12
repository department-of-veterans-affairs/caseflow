class AddNotificationDateToForm8s < ActiveRecord::Migration
  def change
    add_column :form8s, :notification_date, :date
  end
end
