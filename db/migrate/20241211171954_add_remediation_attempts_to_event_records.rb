class AddRemediationAttemptsToEventRecords < ActiveRecord::Migration[6.1]
  def change
    add_column :event_records, :remediation_attempts, :integer, default: 0
  end
end
