class AddAvailableHearingIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :available_hearing_locations, [:appeal_id, :appeal_type], algorithm: :concurrently
  end
end
