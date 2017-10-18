class AddCompletedAttrsToIntakes < ActiveRecord::Migration
  safety_assured # this table is behind a feature flag so it's good

  def change
    add_column :intakes, :completed_at, :datetime
    add_column :intakes, :completion_status, :string

    add_index :intakes, :user_id
  end
end
