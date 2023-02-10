class AddEmailEnabledToNotifications < Caseflow::Migration
  def change
    add_column :notifications, :email_enabled, :boolean, null: false, default: true
  end
end
