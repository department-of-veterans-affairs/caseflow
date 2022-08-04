class ValidateNotificationsForeignKeys < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key "event_type", column: "event_type"
  end
end
