class ValidateNotificationsForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key "notifications", column: "event_type"
  end
end
