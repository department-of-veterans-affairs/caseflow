class DropOriginalLegacyAppealsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :appeals
  end
end
