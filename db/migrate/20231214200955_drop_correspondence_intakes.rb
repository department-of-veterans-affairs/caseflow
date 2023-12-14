class DropCorrespondenceIntakes < ActiveRecord::Migration[5.2]
  def up
    drop_table :correspondence_intakes
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
