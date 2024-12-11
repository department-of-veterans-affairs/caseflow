class AddRemediationStatusToEventRecords < ActiveRecord::Migration[6.1]
  def change
    add_column :event_records, :remediation_status, :integer, default: 0
  end
end
